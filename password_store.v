// ---------------------------------------------------------
// password_store.v   (CHANGED)
// This module is the "memory" of the lock. It keeps the
// 4 password digits.
//
//  * At power-up there is NO password (password_is_set = 0).
//    The first user must type 4 keys to set one.
//  * After that, the password can be changed only when the
//    lock is open (unlocked) and set_mode is ON. So only the
//    person who knows the password can change it.
//
// Reset does NOT erase the password. Reset only locks the
// door again. The password is lost only when the board is
// powered off or re-programmed.
// ---------------------------------------------------------
module password_store (
    input            clk,
    input            reset,
    input            switch,          // 1 = keypad mode
    input            set_mode,        // 1 = user wants to change the password
    input            unlocked,        // 1 = lock is open
    input            key_valid,       // one-clock pulse: a new key just arrived
    input      [3:0] key_code,        // the key that was pressed

    output reg [3:0] pass_digit0,     // saved password, 1st digit
    output reg [3:0] pass_digit1,
    output reg [3:0] pass_digit2,
    output reg [3:0] pass_digit3,     // saved password, 4th digit
    output reg       password_is_set, // 0 = no password yet, 1 = password saved
    output reg [2:0] set_count,       // how many new digits typed so far (0 to 3)
    output reg       new_pass_saved   // one-clock pulse: new password just saved
);

    // we take new digits when:
    //   - no password exists yet, OR
    //   - the lock is open and the user turned set_mode on
    wire taking_new_digits;
    assign taking_new_digits = switch && ((!password_is_set) || (set_mode && unlocked));

    // the new digits wait here until all 4 are typed
    reg [3:0] new_digit0;
    reg [3:0] new_digit1;
    reg [3:0] new_digit2;

    // power-up values (no reset on purpose)
    initial begin
        pass_digit0     = 4'd0;
        pass_digit1     = 4'd0;
        pass_digit2     = 4'd0;
        pass_digit3     = 4'd0;
        password_is_set = 1'b0;
        new_digit0      = 4'd0;
        new_digit1      = 4'd0;
        new_digit2      = 4'd0;
    end

    // keep each new key, and copy all 4 to the password after the 4th key
    always @(posedge clk) begin
        if (taking_new_digits && key_valid) begin
            case (set_count)
                3'd0:    new_digit0 <= key_code;
                3'd1:    new_digit1 <= key_code;
                3'd2:    new_digit2 <= key_code;
                default: begin
                    pass_digit0     <= new_digit0;
                    pass_digit1     <= new_digit1;
                    pass_digit2     <= new_digit2;
                    pass_digit3     <= key_code;
                    password_is_set <= 1'b1;
                end
            endcase
        end
    end

    // count the new keys, and say "saved" after the 4th one
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            set_count      <= 3'd0;
            new_pass_saved <= 1'b0;
        end else begin
            new_pass_saved <= 1'b0;
            if (!taking_new_digits) begin
                set_count <= 3'd0;               // not setting, start fresh
            end else if (key_valid) begin
                if (set_count == 3'd3) begin
                    set_count      <= 3'd0;
                    new_pass_saved <= 1'b1;      // 4 keys done
                end else begin
                    set_count <= set_count + 3'd1;
                end
            end
        end
    end

endmodule
