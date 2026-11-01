// ---------------------------------------------------------
// keypad_decoder.v   (REWRITTEN - noise and bounce proof)
// Reads a 4x4 matrix keypad and tells the lock which key was
// pressed. A real keypad is "shaky": when you press a key the
// metal contacts flicker on and off for a few milliseconds, and
// long jumper wires can pick up small spikes. The old decoder
// counted every flicker as a new key. This one does not.
//
// How it works (3 small steps):
//   SCAN  : drive one column at a time. Wait a little after
//           each change, then read the rows.
//   PRESS : a key was seen. It must stay pressed, without a
//           single break, for PRESS_TIME. If it breaks, it was
//           only a flicker, so start again. Then key_valid
//           goes high for ONE clock.
//   HOLD  : wait until the key is let go and stays let go for
//           RELEASE_TIME. Only then a new key is allowed.
// So: one press = one key, even if you hold it or it flickers.
// ---------------------------------------------------------
module keypad_decoder (
    input            clk,         // 50 MHz
    input            pb,          // not used here, kept to match the top module
    input            switch,      // 1 = keypad mode
    input      [3:0] Row,         // rows from the keypad, 0 = pressed
    output     [3:0] Col,         // columns to the keypad, 0 = driven
    output reg [3:0] DecodeOut,   // the key (0-9, 10=A, 11=B, 12=C, 13=D, 14=*, 15=#)
    output reg       key_valid    // one-clock pulse: a new key was accepted
);

    // times in clock ticks (50 MHz: 1 tick = 20 ns)
    parameter SCAN_TIME    = 16'd500;     // 10 us wait after changing the column
    parameter PRESS_TIME   = 20'd500000;  // key must stay pressed 10 ms
    parameter RELEASE_TIME = 20'd1000000; // key must stay released 20 ms

    // the three steps
    parameter SCAN  = 2'd0;
    parameter PRESS = 2'd1;
    parameter HOLD  = 2'd2;

    reg [1:0]  state;
    reg [1:0]  col_sel;       // column being driven now (0 to 3)
    reg [1:0]  press_row;     // row of the key that was seen
    reg [19:0] timer;

    // the Row wires come from outside, so we pass them through 2 flip-flops
    // first. This keeps the inside of the chip safe from half-changed values.
    reg [3:0] row_first;
    reg [3:0] row_sync;
    always @(posedge clk) begin
        row_first <= Row;
        row_sync  <= row_first;
    end

    // columns follow col_sel (all high when keypad mode is off)
    assign Col = switch ? ~(4'b0001 << col_sel) : 4'b1111;

    // which row is low right now
    reg       row_found;
    reg [1:0] row_idx;
    always @(*) begin
        row_found = 1'b0;
        row_idx   = 2'd0;
        if (!row_sync[0])      begin row_found = 1'b1; row_idx = 2'd0; end
        else if (!row_sync[1]) begin row_found = 1'b1; row_idx = 2'd1; end
        else if (!row_sync[2]) begin row_found = 1'b1; row_idx = 2'd2; end
        else if (!row_sync[3]) begin row_found = 1'b1; row_idx = 2'd3; end
    end

    initial begin
        state     = SCAN;
        col_sel   = 2'd0;
        press_row = 2'd0;
        timer     = 20'd0;
        key_valid = 1'b0;
        DecodeOut = 4'd0;
        row_first = 4'b1111;
        row_sync  = 4'b1111;
    end

    always @(posedge clk) begin
        key_valid <= 1'b0;                       // normally no pulse

        if (!switch) begin
            state   <= SCAN;                     // keypad off, stay idle
            col_sel <= 2'd0;
            timer   <= 20'd0;
        end else begin
            case (state)

                SCAN: begin
                    if (timer >= SCAN_TIME) begin
                        timer <= 20'd0;
                        if (row_found) begin
                            press_row <= row_idx;     // a key may be down here
                            state     <= PRESS;
                        end else begin
                            col_sel <= col_sel + 2'd1; // nothing here, next column
                        end
                    end else begin
                        timer <= timer + 20'd1;
                    end
                end

                PRESS: begin
                    if (row_sync[press_row]) begin    // it broke: only a flicker
                        state <= SCAN;
                        timer <= 20'd0;
                    end else if (timer >= PRESS_TIME) begin
                        key_valid <= 1'b1;            // steady for long enough: accept
                        timer     <= 20'd0;
                        state     <= HOLD;
                        case ({col_sel, press_row})
                            4'b00_00: DecodeOut <= 4'd1;   // C1 R1
                            4'b00_01: DecodeOut <= 4'd4;   // C1 R2
                            4'b00_10: DecodeOut <= 4'd7;   // C1 R3
                            4'b00_11: DecodeOut <= 4'd14;  // C1 R4  (*)
                            4'b01_00: DecodeOut <= 4'd2;   // C2 R1
                            4'b01_01: DecodeOut <= 4'd5;   // C2 R2
                            4'b01_10: DecodeOut <= 4'd8;   // C2 R3
                            4'b01_11: DecodeOut <= 4'd0;   // C2 R4
                            4'b10_00: DecodeOut <= 4'd3;   // C3 R1
                            4'b10_01: DecodeOut <= 4'd6;   // C3 R2
                            4'b10_10: DecodeOut <= 4'd9;   // C3 R3
                            4'b10_11: DecodeOut <= 4'd15;  // C3 R4  (#)
                            4'b11_00: DecodeOut <= 4'd10;  // C4 R1  (A)
                            4'b11_01: DecodeOut <= 4'd11;  // C4 R2  (B)
                            4'b11_10: DecodeOut <= 4'd12;  // C4 R3  (C)
                            default:  DecodeOut <= 4'd13;  // C4 R4  (D)
                        endcase
                    end else begin
                        timer <= timer + 20'd1;
                    end
                end

                default: begin   // HOLD
                    if (!row_sync[press_row]) begin   // still down (or bouncing)
                        timer <= 20'd0;
                    end else if (timer >= RELEASE_TIME) begin
                        state <= SCAN;                // let go long enough: ready again
                        timer <= 20'd0;
                    end else begin
                        timer <= timer + 20'd1;
                    end
                end

            endcase
        end
    end

endmodule
