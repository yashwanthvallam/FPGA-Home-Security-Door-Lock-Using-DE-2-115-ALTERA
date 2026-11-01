// ---------------------------------------------------------
// lock_fsm.v   (REWRITTEN)
// This is the brain of the lock.
//   LOCKED   : waits for 4 keys. After the 4th key it checks
//              all 4 together. Right -> UNLOCKED. Wrong -> DENIED.
//   UNLOCKED : door is open until reset (or a new password is saved).
//   DENIED   : wrong password. Shows the warning for a few
//              seconds, ignores keys, then goes back to LOCKED.
// It does nothing until a password has been set.
// ---------------------------------------------------------
module lock_fsm (
    input            clk,
    input            reset,
    input            switch,           // keypad mode
    input            key_valid,        // one-clock pulse: a new key just arrived
    input      [3:0] bcd,              // the key that was pressed
    input            password_is_set,  // 1 = a password exists
    input      [3:0] pass_digit0,      // saved password
    input      [3:0] pass_digit1,
    input      [3:0] pass_digit2,
    input      [3:0] pass_digit3,
    input            new_pass_saved,   // 1 = new password just saved

    output     [1:0] led,              // led[0] = green (unlocked), led[1] = red (denied)
    output           unlocked,         // 1 = door open
    output           denied,           // 1 = wrong password warning
    output reg [2:0] entry_count,      // how many keys typed so far (0 to 3)
    output     [1:0] state_out         // current state, handy for debug
);

    // the three states
    parameter LOCKED   = 2'd0;
    parameter UNLOCKED = 2'd1;
    parameter DENIED   = 2'd2;

    // how long the wrong-password warning stays (50 MHz clock: 200,000,000 = 4 seconds)
    parameter DENIED_TIME = 28'd200000000;

    reg [1:0]  state;
    reg [27:0] denied_timer;

    // the first three keys wait here until the 4th key arrives
    reg [3:0] entered0;
    reg [3:0] entered1;
    reg [3:0] entered2;

    // true when a key should be counted as a password key
    wire take_key;
    assign take_key = (state == LOCKED) && switch && password_is_set && key_valid;

    // all four keys right?
    wire password_match;
    assign password_match = (entered0 == pass_digit0) && (entered1 == pass_digit1) &&
                            (entered2 == pass_digit2) && (bcd == pass_digit3);

    always @(posedge clk) begin
        if (take_key) begin
            case (entry_count)
                3'd0:    entered0 <= bcd;
                3'd1:    entered1 <= bcd;
                3'd2:    entered2 <= bcd;
                default: entered0 <= entered0;
            endcase
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state        <= LOCKED;
            entry_count  <= 3'd0;
            denied_timer <= 28'd0;
        end else if (new_pass_saved) begin
            state       <= LOCKED;              // new password saved, lock again
            entry_count <= 3'd0;
        end else begin
            case (state)
                LOCKED: begin
                    if (!switch) begin
                        entry_count <= 3'd0;    // keypad off, forget typed keys
                    end else if (take_key) begin
                        if (entry_count == 3'd3) begin
                            entry_count <= 3'd0;
                            if (password_match) begin
                                state <= UNLOCKED;
                            end else begin
                                state        <= DENIED;
                                denied_timer <= 28'd0;
                            end
                        end else begin
                            entry_count <= entry_count + 3'd1;
                        end
                    end
                end
                UNLOCKED: state <= UNLOCKED;     // stays open
                DENIED: begin
                    if (denied_timer >= DENIED_TIME) state <= LOCKED;
                    else denied_timer <= denied_timer + 28'd1;
                end
                default: state <= LOCKED;
            endcase
        end
    end

    assign unlocked  = (state == UNLOCKED);
    assign denied    = (state == DENIED);
    assign led       = {denied, unlocked};
    assign state_out = state;

endmodule
