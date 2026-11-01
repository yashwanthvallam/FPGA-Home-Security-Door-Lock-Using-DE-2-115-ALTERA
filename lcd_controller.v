// ---------------------------------------------------------
// lcd_controller.v   (NEW MODULE)
// Talks to the 16x2 LCD on the DE2-115 (HD44780 type, 8-bit).
// 1) At power-up it sends the start-up commands.
// 2) Then it keeps writing the 32 letters again and again,
//    asking lcd_message_rom for each letter (char_index).
// Because it keeps refreshing, any new message shows up fast.
// ---------------------------------------------------------
module lcd_controller (
    input            clk,              // 50 MHz
    input      [7:0] lcd_char,         // letter for the place we ask
    output     [4:0] char_index,       // place we ask (0 to 31)

    output reg [7:0] LCD_DATA,
    output reg       LCD_RS,           // 0 = command, 1 = letter
    output           LCD_RW,           // always 0 (we only write)
    output reg       LCD_EN,           // pulse that tells the LCD "take it now"
    output           LCD_ON            // always 1 (power the LCD)
);

    // waiting times counted in clock ticks (50 MHz = 20 ns per tick)
    parameter POWER_WAIT = 20'd1000000;  // 20 ms after power-up
    parameter SETUP_TIME = 20'd4;        // data ready before EN goes high
    parameter EN_TIME    = 20'd25;       // EN stays high 500 ns
    parameter SHORT_WAIT = 20'd2500;     // 50 us after a normal write
    parameter LONG_WAIT  = 20'd250000;   // 5 ms after start-up commands

    // the 4 small phases of sending one byte
    parameter PH_POWER = 2'd0;   // wait after power-up
    parameter PH_SETUP = 2'd1;   // put the byte on the wires
    parameter PH_EN    = 2'd2;   // EN high
    parameter PH_WAIT  = 2'd3;   // EN low, wait for the LCD to finish

    // steps:  0..4 start-up commands | 5 = go to line 1 | 6..21 = line 1 letters
    //         22 = go to line 2 | 23..38 = line 2 letters | then back to 5
    parameter STEP_LINE1 = 6'd5;
    parameter STEP_LINE2 = 6'd22;
    parameter STEP_LAST  = 6'd38;

    reg [1:0]  phase;
    reg [19:0] timer;
    reg [5:0]  step;

    reg [7:0]  byte_out;    // byte for this step
    reg        byte_is_letter;
    reg        byte_is_slow;

    initial begin
        phase = PH_POWER;
        timer = 20'd0;
        step  = 6'd0;
        LCD_EN = 1'b0;
        LCD_RS = 1'b0;
        LCD_DATA = 8'd0;
    end

    // the place on the screen for the letter of this step
    assign char_index = (step < STEP_LINE2) ? (step[4:0] - 5'd6) : (step[4:0] - 5'd7);

    assign LCD_RW = 1'b0;
    assign LCD_ON = 1'b1;

    // what to send in this step
    always @(*) begin
        byte_is_letter = 1'b0;
        byte_is_slow   = 1'b0;
        byte_out       = 8'h00;
        case (step)
            6'd0:    begin byte_out = 8'h38; byte_is_slow = 1'b1; end  // 8-bit, 2 lines
            6'd1:    begin byte_out = 8'h38; byte_is_slow = 1'b1; end
            6'd2:    begin byte_out = 8'h0C; byte_is_slow = 1'b1; end  // display on, no cursor
            6'd3:    begin byte_out = 8'h01; byte_is_slow = 1'b1; end  // clear screen
            6'd4:    begin byte_out = 8'h06; end                       // cursor moves right
            STEP_LINE1: byte_out = 8'h80;                              // go to line 1
            STEP_LINE2: byte_out = 8'hC0;                              // go to line 2
            default: begin
                byte_is_letter = 1'b1;
                byte_out       = lcd_char;
            end
        endcase
    end

    always @(posedge clk) begin
        case (phase)
            PH_POWER: begin
                if (timer >= POWER_WAIT) begin
                    timer <= 20'd0;
                    phase <= PH_SETUP;
                end else timer <= timer + 20'd1;
            end
            PH_SETUP: begin
                LCD_DATA <= byte_out;
                LCD_RS   <= byte_is_letter;
                LCD_EN   <= 1'b0;
                if (timer >= SETUP_TIME) begin
                    timer <= 20'd0;
                    phase <= PH_EN;
                end else timer <= timer + 20'd1;
            end
            PH_EN: begin
                LCD_EN <= 1'b1;
                if (timer >= EN_TIME) begin
                    timer  <= 20'd0;
                    LCD_EN <= 1'b0;
                    phase  <= PH_WAIT;
                end else timer <= timer + 20'd1;
            end
            default: begin   // PH_WAIT
                if (timer >= (byte_is_slow ? LONG_WAIT : SHORT_WAIT)) begin
                    timer <= 20'd0;
                    phase <= PH_SETUP;
                    if (step == STEP_LAST) step <= STEP_LINE1;
                    else                   step <= step + 6'd1;
                end else timer <= timer + 20'd1;
            end
        endcase
    end

endmodule
