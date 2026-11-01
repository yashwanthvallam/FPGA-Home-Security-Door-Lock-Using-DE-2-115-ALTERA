// ---------------------------------------------------------
// home_security_lock.v   (TOP MODULE, CHANGED)
// Door lock with a keypad and the 16x2 LCD of the DE2-115.
//
//  First use : the LCD asks the user to SET a password (4 keys).
//  After that: type the 4 keys to open the lock.
//              Right password -> "WELCOME USER", green LED.
//              Wrong password -> "ACCESS DENIED ... CAUTION!!!", red LED.
//  Change    : open the lock, turn set_mode ON, type 4 new keys.
//              Only someone who knows the password can do this.
//
//   switch = 0 : keypad off. Green LED follows the pushbutton pb.
//   switch = 1 : keypad on.
//   reset      : locks the door again (password is kept).
// ---------------------------------------------------------
module home_security_lock (
    input        clk,
    input        reset,
    input        pb,           // pushbutton, active low
    input        switch,       // 0 = keypad off, 1 = keypad on
    input        set_mode,     // 1 = change the password (only when unlocked)
    input  [3:0] Row,          // keypad rows
    output [3:0] Col,          // keypad columns
    output [1:0] led,          // led[0] = green, led[1] = red

    output [7:0] LCD_DATA,     // LCD pins
    output       LCD_RS,
    output       LCD_RW,
    output       LCD_EN,
    output       LCD_ON
);

    // wires between the modules
    wire [3:0] key_code;         // the key that was pressed
    wire       key_valid;        // pulse: a new key arrived
    wire       password_is_set;  // 1 = a password has been saved
    wire [3:0] pass_digit0;      // saved password
    wire [3:0] pass_digit1;
    wire [3:0] pass_digit2;
    wire [3:0] pass_digit3;
    wire [2:0] set_count;        // new digits typed while setting a password
    wire       new_pass_saved;   // pulse: new password saved
    wire       unlocked;         // 1 = door open
    wire       denied;           // 1 = wrong password
    wire [2:0] entry_count;      // keys typed while opening
    wire [1:0] fsm_led;
    wire [1:0] fsm_state;
    wire [2:0] message_id;       // which message the LCD must show
    wire [4:0] char_index;       // place on the LCD (0 to 31)
    wire [7:0] lcd_char;         // letter for that place

    // 1) read the keypad
    keypad_decoder u_decoder (
        .clk        (clk),
        .pb         (pb),
        .switch     (switch),
        .Row        (Row),
        .Col        (Col),
        .DecodeOut  (key_code),
        .key_valid  (key_valid)
    );

    // 2) keep the password, and save a new one when asked
    password_store u_password (
        .clk             (clk),
        .reset           (reset),
        .switch          (switch),
        .set_mode        (set_mode),
        .unlocked        (unlocked),
        .key_valid       (key_valid),
        .key_code        (key_code),
        .pass_digit0     (pass_digit0),
        .pass_digit1     (pass_digit1),
        .pass_digit2     (pass_digit2),
        .pass_digit3     (pass_digit3),
        .password_is_set (password_is_set),
        .set_count       (set_count),
        .new_pass_saved  (new_pass_saved)
    );

    // 3) check the typed keys against the password
    lock_fsm u_fsm (
        .clk             (clk),
        .reset           (reset),
        .switch          (switch),
        .key_valid       (key_valid),
        .bcd             (key_code),
        .password_is_set (password_is_set),
        .pass_digit0     (pass_digit0),
        .pass_digit1     (pass_digit1),
        .pass_digit2     (pass_digit2),
        .pass_digit3     (pass_digit3),
        .new_pass_saved  (new_pass_saved),
        .led             (fsm_led),
        .unlocked        (unlocked),
        .denied          (denied),
        .entry_count     (entry_count),
        .state_out       (fsm_state)
    );

    // 4) choose the message
    message_picker u_message_picker (
        .switch          (switch),
        .set_mode        (set_mode),
        .password_is_set (password_is_set),
        .unlocked        (unlocked),
        .denied          (denied),
        .message_id      (message_id)
    );

    // 5) turn the message into letters
    lcd_message_rom u_message_rom (
        .message_id  (message_id),
        .char_index  (char_index),
        .entry_count (entry_count),
        .set_count   (set_count),
        .lcd_char    (lcd_char)
    );

    // 6) send the letters to the LCD
    lcd_controller u_lcd (
        .clk        (clk),
        .lcd_char   (lcd_char),
        .char_index (char_index),
        .LCD_DATA   (LCD_DATA),
        .LCD_RS     (LCD_RS),
        .LCD_RW     (LCD_RW),
        .LCD_EN     (LCD_EN),
        .LCD_ON     (LCD_ON)
    );

    // final LED output: keypad off uses pb directly,
    // keypad on uses the lock result
    assign led[0] = switch ? fsm_led[0] : ~pb;   // green
    assign led[1] = switch ? fsm_led[1] : pb;    // red

endmodule
