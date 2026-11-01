// ---------------------------------------------------------
// message_picker.v   (SIMPLIFIED)
// Chooses which message the LCD must show right now.
// There is only ONE screen for each situation. Nothing
// changes by itself. Six screens in total:
//
//  MSG_SET    : no password yet      WELCOME. SET NEW / PASSWORD: ____
//  MSG_LOCKED : password is set      PASSWORD IS SET  / ENTER: ____
//  MSG_OPEN   : right password       WELCOME USER     / LOCK IS OPEN
//  MSG_CHANGE : changing password    CHANGE PASSWORD  / NEW KEYS: ____
//  MSG_DENIED : wrong password       ACCESS DENIED!!! / WRONG PASSWORD
//  MSG_OFF    : switch SW0 is down   KEYPAD IS OFF    / TURN SW0 UP
// ---------------------------------------------------------
module message_picker (
    input            switch,
    input            set_mode,
    input            password_is_set,
    input            unlocked,
    input            denied,
    output reg [2:0] message_id
);

    parameter MSG_SET    = 3'd0;
    parameter MSG_LOCKED = 3'd1;
    parameter MSG_OPEN   = 3'd2;
    parameter MSG_CHANGE = 3'd3;
    parameter MSG_DENIED = 3'd4;
    parameter MSG_OFF    = 3'd5;

    always @(*) begin
        if (!switch)               message_id = MSG_OFF;
        else if (!password_is_set) message_id = MSG_SET;
        else if (denied)           message_id = MSG_DENIED;
        else if (unlocked)         message_id = set_mode ? MSG_CHANGE : MSG_OPEN;
        else                       message_id = MSG_LOCKED;
    end

endmodule
