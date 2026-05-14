# UART Protocol — Verilog Implementation

## Overview
A complete UART (Universal Asynchronous Receiver Transmitter) implementation
in Verilog, including transmitter, receiver, and testbench.

## Files
- uart_tx.v  — Transmitter FSM (3-always block style)
- uart_rx.v  — Receiver FSM with 16x oversampling and double flop synchronizer
- uart_tb.v  — Testbench that sends 6 test bytes and verifies received output

## Parameters
| Parameter      | Value | Description                        |
|----------------|-------|------------------------------------|
| clk_per_bit    | 868   | Clock cycles per bit (TX)          |
| clks_per_bit   | 868   | Clock cycles per bit (RX)          |
| clks_per_sample| 54    | Clock cycles per sample tick (RX)  |

## Baud Rate
- Clock frequency: 100 MHz
- Baud rate: 115200
- Clocks per bit: 100,000,000 / 115,200 = 868

## FSM States
### TX
IDLE → START → DATA_BITS → STOP → CLEANUP → IDLE

### RX
IDLE → START → DATA_BITS → STOP → CLEANUP → IDLE

## Key Design Features
- 3-always block FSM style (state register, next state logic, datapath)
- 16x oversampling in RX for robust bit center sampling
- Double flop synchronizer on RX input to prevent metastability
- Stop bit verification in RX to detect framing errors
- named bit_done wire in TX for clean readable transitions

## Test Results
Tested with 6 bytes: 0x37, 0x55, 0xAA, 0xFF, 0x00, 0xA5
All bytes passed successfully in Vivado XSim behavioral simulation.

## Tools
- Xilinx Vivado 2023
- Basys3 / XSim simulator
