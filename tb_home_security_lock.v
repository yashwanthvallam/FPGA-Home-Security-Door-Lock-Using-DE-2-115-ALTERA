// ---------------------------------------------------------
// tb_home_security_lock.v   (TEST)
// Acts like a small LCD: it reads what the design writes to
// the LCD pins and keeps the 32 letters in lcd_mem.
// Then it checks the text in every situation:
//   1) first power-up: asks to set a password
//   2) set password 1-3-5-9
//   3) wrong password -> ACCESS DENIED, red LED
//   4) right password -> WELCOME USER, green LED
//   5) change password (needs the old password first)
//   6) old password fails, new one works
//   7) set_mode used while locked does NOT change the password
// ---------------------------------------------------------
`timescale 1ns/1ps

module tb_home_security_lock;

    reg        clk;
    reg        reset;
    reg        pb;
    reg        switch;
    reg        set_mode;
    reg  [3:0] Row;
    wire [3:0] Col;
    wire [1:0] led;
    wire [7:0] LCD_DATA;
    wire       LCD_RS, LCD_RW, LCD_EN, LCD_ON;

    integer errors;

    // ---------- pretend keypad ----------
    reg       pressed;
    reg [1:0] press_col, press_row;
    always @(*) begin
        Row = 4'b1111;
        if (pressed && (Col == ~(4'b0001 << press_col)))
            Row[press_row] = 1'b0;
    end

    home_security_lock dut (
        .clk(clk), .reset(reset), .pb(pb), .switch(switch), .set_mode(set_mode),
        .Row(Row), .Col(Col), .led(led),
        .LCD_DATA(LCD_DATA), .LCD_RS(LCD_RS), .LCD_RW(LCD_RW), .LCD_EN(LCD_EN), .LCD_ON(LCD_ON)
    );

    // make the waiting times short so the test runs fast
    defparam dut.u_lcd.POWER_WAIT           = 100;
    defparam dut.u_lcd.SHORT_WAIT           = 40;
    defparam dut.u_lcd.LONG_WAIT            = 100;
    defparam dut.u_fsm.DENIED_TIME          = 15000;
    defparam dut.u_decoder.SCAN_TIME        = 4;
    defparam dut.u_decoder.PRESS_TIME       = 3;
    defparam dut.u_decoder.RELEASE_TIME     = 3;

    always #5 clk = ~clk;

    // ---------- pretend LCD ----------
    reg [7:0] lcd_mem [0:31];
    integer   lcd_pos;
    integer   i;
    initial begin
        lcd_pos = 0;
        for (i = 0; i < 32; i = i + 1) lcd_mem[i] = " ";
    end
    always @(negedge LCD_EN) begin
        if (LCD_RS == 1'b0) begin
            if (LCD_DATA == 8'h80) lcd_pos = 0;
            if (LCD_DATA == 8'hC0) lcd_pos = 16;
        end else begin
            lcd_mem[lcd_pos] = LCD_DATA;
            lcd_pos = lcd_pos + 1;
        end
    end

    reg [255:0] lcd_text;
    task read_lcd;
        integer k;
        begin
            for (k = 0; k < 32; k = k + 1)
                lcd_text[255 - 8*k -: 8] = lcd_mem[k];
        end
    endtask

    task check_lcd(input [255:0] expected, input [639:0] name);
        begin
            #70000;                        // wait for one full LCD refresh
            read_lcd;
            if (lcd_text === expected)
                $display("PASS: %0s", name);
            else begin
                $display("FAIL: %0s", name);
                $display("      LCD shows: [%0s]", lcd_text);
                errors = errors + 1;
            end
        end
    endtask

    task check_leds(input [1:0] expected, input [639:0] name);
        begin
            if (led === expected) $display("PASS: %0s (led=%b)", name, led);
            else begin $display("FAIL: %0s (led=%b, wanted %b)", name, led, expected); errors = errors + 1; end
        end
    endtask

    // ---------- pressing keys ----------
    task press_key(input [1:0] col_sel, input [1:0] row_sel);
        begin
            press_col = col_sel; press_row = row_sel; pressed = 1'b1;
            #600; pressed = 1'b0; #300;
        end
    endtask
    task key_1; press_key(2'd0, 2'd0); endtask
    task key_2; press_key(2'd1, 2'd0); endtask
    task key_3; press_key(2'd2, 2'd0); endtask
    task key_4; press_key(2'd0, 2'd1); endtask
    task key_5; press_key(2'd1, 2'd1); endtask
    task key_6; press_key(2'd2, 2'd1); endtask
    task key_8; press_key(2'd1, 2'd2); endtask
    task key_9; press_key(2'd2, 2'd2); endtask

    initial begin
        errors = 0; clk = 0; reset = 1; pb = 1; switch = 0; set_mode = 0; pressed = 0;
        #100 reset = 0;

        // keypad off
        check_lcd("KEYPAD IS OFF   TURN SW0 UP     ", "keypad off message");

        // 1) first use: no password yet
        switch = 1;
        check_lcd("WELCOME. SET NEWPASSWORD: ____  ", "first power-up asks for a password");

        // 2) set the password 1-3-5-9
        key_1; key_3; key_5;
        check_lcd("WELCOME. SET NEWPASSWORD: ***_  ", "stars while setting the password");
        key_9;
        check_lcd("PASSWORD IS SET ENTER: ____     ", "password is set");

        // 3) wrong password
        key_1; key_3; key_5;
        check_lcd("PASSWORD IS SET ENTER: ***_     ", "stars while typing");
        key_8;
        check_lcd("ACCESS DENIED!!!WRONG PASSWORD  ", "wrong password message");
        check_leds(2'b10, "red led on");
        #100000;
        check_lcd("PASSWORD IS SET ENTER: ____     ", "back to locked after warning");

        // 4) right password
        key_1; key_3; key_5; key_9;
        check_lcd("WELCOME USER    LOCK IS OPEN    ", "welcome user");
        check_leds(2'b01, "green led on");

        // 5) change the password to 2-4-6-8 (door is open)
        set_mode = 1;
        check_lcd("CHANGE PASSWORD NEW KEYS: ____  ", "change password asks for keys");
        key_2; key_4; key_6; key_8;
        set_mode = 0;
        check_lcd("PASSWORD IS SET ENTER: ____     ", "new password saved, locked again");

        // 6) old password fails, new one works
        key_1; key_3; key_5; key_9;
        check_lcd("ACCESS DENIED!!!WRONG PASSWORD  ", "old password is refused");
        #100000;
        key_2; key_4; key_6; key_8;
        check_lcd("WELCOME USER    LOCK IS OPEN    ", "new password opens the lock");

        // 7) reset keeps the password, set_mode while locked changes nothing
        reset = 1; #40 reset = 0;
        set_mode = 1;
        key_5; key_5; key_5; key_5;           // counted as a (wrong) try, not a new password
        check_lcd("ACCESS DENIED!!!WRONG PASSWORD  ", "set_mode while locked is just a wrong try");
        set_mode = 0;
        #100000;
        key_2; key_4; key_6; key_8;
        check_lcd("WELCOME USER    LOCK IS OPEN    ", "password unchanged after reset");

        if (LCD_RW === 1'b0 && LCD_ON === 1'b1) $display("PASS: LCD_RW=0, LCD_ON=1");
        else begin $display("FAIL: LCD_RW / LCD_ON"); errors = errors + 1; end

        if (errors == 0) $display("ALL TESTS PASSED");
        else             $display("%0d TEST(S) FAILED", errors);
        $finish;
    end

endmodule
