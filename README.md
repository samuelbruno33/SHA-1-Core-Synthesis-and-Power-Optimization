# Group 26 - Synthesis and Optimization of Digital Systems

This project implements a complete logic synthesis, power optimization, and static timing analysis flow for the `sha1_core` hardware cryptographic module. The flow utilizes the **STMicroelectronics 65nm (STcmos65)** technology library and standard industry EDA tools to analyze Power, Performance, and Area (PPA) metrics.

## 📂 Project Directory Structure

The repository is strictly organized to separate the source files, technology databases, and the final delivery archive:

- `rtl/sha1_core/`: Contains the Verilog RTL source code (`src/`), the testbench (`tb/`), and SDC timing constraints (`sdc/`).
- `tech/STcmos65/`: Contains the technology libraries (`.db` files) and compiled simulation libraries (`vsimlib`).
- `saved/sha1_core/`: Working directory dynamically used to output post-synthesis netlists (`synthesis/`) and switching activity traces (`simulation/`).
- `Group26/`: The final delivery folder, divided into individual subdirectories for each exercise (`ex1/`, `ex2.1/`, `ex2.2/`, `ex3/`). Each contains its isolated `synopsys_dc.setup`, `synopsys_pt.setup`, and TCL scripts.

## 🛠️ Prerequisites & EDA Tools
- **Synopsys Design Compiler (DC)**: Logic synthesis and physical mapping (`dc_shell`).
- **Synopsys PrimeTime (PT)**: Static Timing Analysis (STA) and Power Analysis (`pt_shell`).
- **Mentor/Siemens QuestaSIM**: Gate-level functional simulation for Switching Activity (SWA) generation (`vlog`, `vsim`).

---

## 🚀 Methodology & Execution Guide

**IMPORTANT:** All commands listed below must be executed from the root directory of the project (`WORK_Group26`), except during the QuestaSIM simulation steps, where changing directories is strictly required to avoid polluting the root with temporary files.

### Exercise 1: Baseline Synthesis
- **Objective**: Find the minimum working clock period (in multiples of 0.5 ns) using exclusively the High-Vt (HVT) library, ensuring positive Setup Slack and Area $\le$ 24100 $\mu m^2$.
- **Solution**: Iterative synthesis sweeps revealed that a **5.5 ns** clock period successfully meets all constraints. Power metrics are calculated via VCD back-annotation.
- **Execution**:
  1. *(Synthesis was pre-provided and immutable for Ex 1)*
  2. Generate the VCD:
     ```bash
     cd saved/sha1_core/simulation/
     vlog ../synthesis/sha1_core_postsyn.v ../../../rtl/sha1_core/tb/tb_sha1_core.v -work work_swa
     vsim -c -t ns -L ../../../tech/STcmos65/vsimlib work_swa.tb_sha1_core -voptargs=+acc=np+sha1_core
     ```
     *Inside the VSIM prompt, extract the trace:*
     ```tcl
     vcd file sha1_core.vcd
     vcd add -file sha1_core.vcd -ports /tb_sha1_core/dut/*
     vcd add -file sha1_core.vcd -internal /tb_sha1_core/dut/*
     run -all
     quit -sim
     ```
  3. Analyze PPA:
     ```bash
     cd ../../..
     pt_shell -f ./Group26/ex1/pt_analysis.tcl
     ```

### Exercise 2.1: Power Optimization (Clock Gating)
- **Objective**: Implement clock gating to reduce dynamic power using the 5.5 ns clock period.
- **Solution**: Added `set_clock_gating_style` constraints (minimum bit-width: 8, maximum fanout: 32) and compiled with the `-gate_clock` flag. This successfully inserted latches and AND gates into the clock tree, drastically dropping the Dynamic Power.
- **Execution**:
  1. Synthesize:
     ```bash
     dc_shell -f ./Group26/ex2.1/synthesis.tcl
     ```
  2. Simulate the new netlist (Follow the exact `cd`, `vlog`, `vsim` and TCL steps from Ex 1).
  3. Analyze PPA:
     ```bash
     cd ../../..
     pt_shell -f ./Group26/ex2.1/pt_analysis.tcl
     ```

### Exercise 2.2: Power Optimization (Clock Gating + Multi-VT)
- **Objective**: Keep clock gating enabled and introduce Multi-Threshold Voltage (Multi-VT) libraries (LVT, SVT, HVT) to optimize leakage power (`set_max_leakage_power 0`).
- **Solution**: The setup files were updated to include all three `.db` libraries, mapped internally using the `find library` command. The synthesis engine automatically performed a Multi-VT swap. To meet intermediate timing rules introduced by the gating logic, DC heuristically allocated ~21.5% LVT cells and ~78.5% HVT cells.
- **Execution**:
  1. Synthesize:
     ```bash
     dc_shell -f ./Group26/ex2.2/synthesis.tcl
     ```
  2. Simulate the new netlist (Follow the exact `cd`, `vlog`, `vsim` and TCL steps from Ex 1).
  3. Analyze PPA:
     ```bash
     cd ../../..
     pt_shell -f ./Group26/ex2.2/pt_analysis.tcl
     ```

### Exercise 3: Custom Timing Report (TCL Scripting)
- **Objective**: Write a custom TCL procedure (`custom_report.tcl`) inside PrimeTime to extract the top $N$ critical paths, isolating only the combinational logic.
- **Solution**: The script uses `get_timing_paths` and iterates over path points. It features robust safety checks, filters out sequential elements (`is_combinational == true`), and relies on temporary arrays to prevent double-counting if a path traverses both the input and output pins of the same logic gate. Results are sorted in descending order of occurrence.
- **Execution**:
  1. Run the PrimeTime analysis script (which automatically sources and invokes `custom_report 50 max`):
     ```bash
     pt_shell -f ./Group26/ex3/pt_analysis.tcl
     ```
