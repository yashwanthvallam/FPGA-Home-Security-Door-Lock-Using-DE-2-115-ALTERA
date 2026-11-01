// ---------------------------------------------------------
// lcd_message_rom.v   (SIMPLIFIED)
// A small "list of messages". Give it the message number and
// the place on the screen (0 to 31), and it gives back the
// letter for that place.
//   place 0..15  = top line, left to right
//   place 16..31 = bottom line, left to right
// Each message is exactly 32 letters (16 + 16).
// The "____" in a message turns into "*" for every key typed.
// ---------------------------------------------------------
module lcd_message_rom (
    input      [2:0]  message_id,
    input      [4:0]  char_index,   // place on the screen, 0 to 31
    input      [2:0]  entry_count,  // keys typed while opening
    input      [2:0]  set_count,    // keys typed while setting a password
    output reg [7:0]  lcd_char
);

    // same numbers as in message_picker.v
    parameter MSG_SET    = 3'd0;
    parameter MSG_LOCKED = 3'd1;
    parameter MSG_OPEN   = 3'd2;
    parameter MSG_CHANGE = 3'd3;
    parameter MSG_DENIED = 3'd4;

    reg [255:0] text;
    reg [255:0] shifted;
    reg [4:0]   first_box;    // place where the 4 boxes "____" start
    reg [2:0]   keys_typed;   // how many boxes become stars
    reg         has_boxes;

    always @(*) begin
        has_boxes  = 1'b0;
        first_box  = 5'd26;
        keys_typed = set_count;
        case (message_id)
            MSG_SET: begin
                text      = "WELCOME. SET NEWPASSWORD: ____  ";
                has_boxes = 1'b1;
                first_box = 5'd26;
                keys_typed = set_count;
            end
            MSG_LOCKED: begin
                text      = "PASSWORD IS SET ENTER: ____     ";
                has_boxes = 1'b1;
                first_box = 5'd23;
                keys_typed = entry_count;
            end
            MSG_OPEN:   text = "WELCOME USER    LOCK IS OPEN    ";
            MSG_CHANGE: begin
                text      = "CHANGE PASSWORD NEW KEYS: ____  ";
                has_boxes = 1'b1;
                first_box = 5'd26;
                keys_typed = set_count;
            end
            MSG_DENIED: text = "ACCESS DENIED!!!WRONG PASSWORD  ";
            default:    text = "KEYPAD IS OFF   TURN SW0 UP     ";
        endcase

        // pick the letter at this place
        shifted  = text >> (8 * (31 - char_index));
        lcd_char = shifted[7:0];

        // typed keys become stars
        if (has_boxes && char_index >= first_box && char_index <= first_box + 5'd3) begin
            if ((char_index - first_box) < {2'd0, keys_typed}) lcd_char = "*";
        end
    end

endmodule
