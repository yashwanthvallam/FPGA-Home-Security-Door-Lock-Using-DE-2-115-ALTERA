# How to Run the Door Lock on the DE2-115 — Step by Step

Follow the steps in order. Do not skip any.

## 0. What you need
- DE2-115 board, its 12 V power adapter, and the USB-Blaster cable (USB-A to USB-B)
- A 4x4 keypad (8 pins)
- 8 jumper wires
- A PC with Quartus (the one you already use)
- The 7 project files in this folder:
  `home_security_lock.v`, `keypad_decoder.v`, `password_store.v`, `lock_fsm.v`,
  `message_picker.v`, `lcd_message_rom.v`, `lcd_controller.v`
- `pin_assignments.tcl` (the pins)

`tb_home_security_lock.v` is only for testing on the PC. Do not add it to Quartus.

## 0b. Check the keypad first (5 minutes, recommended)
Open the folder `keypad_test` and follow `Keypad_Test_Steps.md`. It shows with LEDs that one press gives exactly one key. Do this before the lock.

## 1. Wire the keypad (board OFF)
Your keypad has 8 pins in a row: `R1 R2 R3 R4 C1 C2 C3 C4`. Push one jumper wire into each hole, one by one, and connect it to the GPIO header on the board like this:

| Keypad pin | Name | Board GPIO | FPGA pin |
|---|---|---|---|
| 1 | R1 | GPIO[0] | PIN_AB22 |
| 2 | R2 | GPIO[1] | PIN_AC15 |
| 3 | R3 | GPIO[2] | PIN_AB21 |
| 4 | R4 | GPIO[3] | PIN_Y17 |
| 5 | C1 | GPIO[4] | PIN_AC21 |
| 6 | C2 | GPIO[5] | PIN_Y16 |
| 7 | C3 | GPIO[6] | PIN_AD21 |
| 8 | C4 | GPIO[7] | PIN_AE16 |

No power wire is needed for the keypad.
Before you power on, check the GPIO header figure in the DE2-115 user manual so you know which header hole is GPIO[0] to GPIO[7]. Pin 1 of the header has a mark printed on the board.

## 2. Make the Quartus project
1. Open Quartus. Click **File > New Project Wizard**. Click Next.
2. Choose a folder and type the project name `home_security_lock`. Next.
3. Click **Add All** or add the 7 `.v` files one by one (see the list in step 0). Next.
4. Family: **Cyclone IV E**. Device: **EP4CE115F29C7**. Next, then Finish.
5. Check the top module: **Assignments > Settings > General**, "Top-level entity" must be `home_security_lock`.

## 3. Put in the pins
1. **Tools > Tcl Scripts...**
2. Click `pin_assignments.tcl`, then **Run**.
3. Wait for the message "Pin assignments applied and saved."

The script sets the clock, switches, keypad pins, LEDs and LCD pins. It also turns on pull-up resistors for the 4 keypad row pins. The keypad does not work without them.

## 4. Compile
1. Click **Processing > Start Compilation** (or the blue play button).
2. Wait a few minutes. At the end you must see "Full Compilation was successful" with 0 errors.
3. Warnings are normal. Only errors matter.

## 5. Get the board ready
1. Plug the 12 V adapter into the board and into the wall.
2. Plug the USB-Blaster cable from the board's **USB Blaster** port to your PC.
3. Find the small **RUN / PROG** slide switch on the board (bottom-left, "Programming Mode Switch"). Set it to **RUN**.
4. Press the red power button. The board lights up.
5. Put the slide switches like this:
   - SW17 **down** (reset off)
   - SW1 **down** (change-password off)
   - SW0 **up** (keypad on)

## 6. Send the design to the board
1. In Quartus click **Tools > Programmer**.
2. Click **Hardware Setup...**, pick **USB-Blaster**, click Close.
3. Mode must say **JTAG**.
4. Click **Auto Detect**. If it asks for the device, pick `EP4CE115`.
5. Right-click the chip row, choose **Change File**, and pick `output_files/home_security_lock.sof`.
6. Tick the **Program/Configure** box.
7. Click **Start**. Wait for 100% (Successful).

The LCD now shows:

```
WELCOME. SET NEW
PASSWORD: ____
```

## 7. Use it

| What you want | What you do | LCD shows |
|---|---|---|
| Set your password | Press any 4 keys | `PASSWORD: ***_` while typing, then `PASSWORD IS SET / ENTER: ____` |
| Open the lock | Press your 4 keys | `WELCOME USER / LOCK IS OPEN`, green LED on |
| Wrong password | Press 4 wrong keys | `ACCESS DENIED!!! / WRONG PASSWORD`, red LED on for 4 seconds, then back to `ENTER: ____` |
| Change your password | Open the lock. Flip **SW1 up**. Press 4 new keys. Flip SW1 down. | `CHANGE PASSWORD / NEW KEYS: ____`, then the lock closes and shows `PASSWORD IS SET` |
| Lock the door again | Flip **SW17 up**, then down | `PASSWORD IS SET / ENTER: ____` |
| Keypad off | SW0 down | `KEYPAD IS OFF / TURN SW0 UP` |

Check the new password works: after you set or change it, press the new 4 keys. The lock must open.

## 8. Important things to know
- The password is saved inside the FPGA. If you switch the board off or load the design again, the password is gone and the LCD asks for a new one.
- Reset (SW17) only locks the door. It does not erase the password.
- Only a person who knows the password can change it (the door must be open first).
- The keys `*` and `#` can also be part of a password.
- Press each key firmly, hold it for about half a second, then let go. The `*` appears after about 10 ms of steady press. A short flicker or noise is ignored on purpose.
- One press counts as one key, even if you hold it down. To enter the same key twice (like 2, 2), let go for a moment (about 20 ms) and press again.

## 9. If something is wrong

| Problem | What to do |
|---|---|
| LCD is blank | Switch the board off and on, then program again. Check the LCD pins were set (step 3). |
| LCD shows odd letters | Switch off and on, then program again. |
| Programmer says "No Hardware" | Cable not plugged in, board is off, or the USB-Blaster driver is missing. Check Windows Device Manager. |
| Keys do nothing | SW0 must be up. SW17 must be down. Check the 8 keypad wires. |
| Wrong keys appear or keys press by themselves | A keypad wire is on the wrong hole, or a row wire is loose. Check the wire table in step 1. Run the keypad check (step 0b). |
| One press gives 2 stars | Use the latest `keypad_decoder.v` (the one in this folder). Older versions counted every contact flicker. |
| `ACCESS DENIED` even with the right password | Press exactly 4 keys. The lock only checks after the 4th key. |
| Compile error "can't find module" | One of the 7 `.v` files is not added to the project (step 2). |
