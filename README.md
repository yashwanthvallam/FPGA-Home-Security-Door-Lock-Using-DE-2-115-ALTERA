FPGA-Based Home Security Door Lock

Project Overview

The FPGA-Based Home Security Door Lock is a digital security system designed using Verilog HDL and implemented on the Altera DE2-115 FPGA development board.

The system uses a keypad interface to accept password input, verifies the entered password, and controls the door lock based on authentication. An LCD interface provides feedback regarding the lock status and system operations.

Key Features

- Password-based door access control.
- Keypad input decoding using Verilog HDL.
- FSM-based lock control.
- Password storage and verification.
- LCD interfacing for displaying system messages.
- Modular RTL architecture.
- Functional verification using a Verilog testbench.
- FPGA implementation support for the DE2-115 board.

Hardware and Software Requirements

Hardware:
- Altera DE2-115 FPGA Development Board
- Matrix Keypad
- LCD Display
- Connecting wires and peripherals

Software:
- Intel Quartus Prime
- Verilog HDL
- ModelSim (for simulation)

Project Modules:

| Module | Description |
|---|---|
| `home_security_lock.v` | Top-level module |
| `keypad_decoder.v` | Decodes keypad input |
| `lock_fsm.v` | FSM-based lock control |
| `password_store.v` | Password storage and verification |
| `message_picker.v` | Selects LCD messages |
| `lcd_controller.v` | LCD interfacing |
| `lcd_message_rom.v` | Stores LCD messages |
| `tb_home_security_lock.v` | Functional verification testbench |

Repository Structure :

```text
FPGA-Home-Security-Door-Lock/
│
├── home_security_lock.v
├── keypad_decoder.v
├── lock_fsm.v
├── password_store.v
├── message_picker.v
├── lcd_controller.v
├── lcd_message_rom.v
│
├── tb_home_security_lock.v
├── pin_assignments.tcl
├── How_To_Run_On_DE2-115.md
├── README.md
│
└── Images/
    ├── FPGA_Setup.jpg
    ├── Keypad_Interface.jpg
    └── LCD_Output.jpg
```

 Working Principle

1. The user enters a password through the keypad.
2. The keypad decoder processes the input.
3. The password verification module checks the entered password.
4. The FSM controls the lock operation based on authentication.
5. The LCD displays appropriate system messages.
6. The system maintains the appropriate lock state.

 Implementation

The design is developed using Verilog HDL with a modular RTL approach. Individual modules are integrated through the top-level module, `home_security_lock.v`.

A Verilog testbench is provided for functional verification, along with a pin assignment file for FPGA hardware interfacing.

 Simulation and FPGA Implementation

1. Add the Verilog source files to an Intel Quartus Prime project.
2. Set `home_security_lock` as the top-level entity.
3. Apply the DE2-115 FPGA pin assignments.
4. Run functional simulation using the provided testbench.
5. Compile and program the FPGA board.

Refer to `How_To_Run_On_DE2-115.md` for hardware setup instructions.

 Applications

- Digital door access control systems.
- Password-based security systems.
- FPGA-based embedded security applications.
- Digital authentication systems.

 Technologies Used

`Verilog HDL` | `RTL Design` | `FSM` | `FPGA` | `Intel Quartus Prime` | `DE2-115`

 Author

Vallam Yaswanth

M.Tech – VLSI Design

Acknowledgement :
This project was developed to explore Verilog RTL design, finite state machines, digital interfacing, and FPGA hardware implementation.
