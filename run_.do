if [file exists work] {
    vdel -all -lib work
}
vlib work
vmap work work

# Compile submodules first
vlog -sv pipe_reg.v
vlog -sv mux4.v
vlog -sv preadder_sub.v
vlog -sv postadder_sub.v

# Compile top-level DSP48A1
vlog -sv dsp48a1_top.v

# Compile testbench
vlog -sv dsp48a1_tb_.v

# Load the design
vsim -voptargs=+acc work.DSP48A1_tb

# Add all signals to the waveform window
add wave -radix hex sim:/DSP48A1_tb/CLK
add wave -radix hex sim:/DSP48A1_tb/OPMODE
add wave -radix decimal sim:/DSP48A1_tb/A
add wave -radix decimal sim:/DSP48A1_tb/B
add wave -radix decimal sim:/DSP48A1_tb/C
add wave -radix decimal sim:/DSP48A1_tb/D
add wave -radix hex sim:/DSP48A1_tb/BCIN
add wave -radix hex sim:/DSP48A1_tb/PCIN
add wave -radix hex sim:/DSP48A1_tb/CARRYIN

add wave -divider "Resets"
add wave sim:/DSP48A1_tb/RSTA
add wave sim:/DSP48A1_tb/RSTB
add wave sim:/DSP48A1_tb/RSTC
add wave sim:/DSP48A1_tb/RSTD
add wave sim:/DSP48A1_tb/RSTM
add wave sim:/DSP48A1_tb/RSTP
add wave sim:/DSP48A1_tb/RSTCARRYIN
add wave sim:/DSP48A1_tb/RSTOPMODE

add wave -divider "Clock Enables"
add wave sim:/DSP48A1_tb/CEA
add wave sim:/DSP48A1_tb/CEB
add wave sim:/DSP48A1_tb/CEC
add wave sim:/DSP48A1_tb/CED
add wave sim:/DSP48A1_tb/CEM
add wave sim:/DSP48A1_tb/CEP
add wave sim:/DSP48A1_tb/CECARRYIN
add wave sim:/DSP48A1_tb/CEOPMODE

add wave -divider "Outputs"
add wave -radix hex sim:/DSP48A1_tb/BCOUT
add wave -radix hex sim:/DSP48A1_tb/PCOUT
add wave -radix hex sim:/DSP48A1_tb/P
add wave -radix hex sim:/DSP48A1_tb/M
add wave sim:/DSP48A1_tb/CARRYOUT
add wave sim:/DSP48A1_tb/CARRYOUTF

# Internal signal

add wave -divider "Internal DUT signals (through submodule instances)"
add wave -radix hex sim:/DSP48A1_tb/dut/d_reg_out
add wave -radix hex sim:/DSP48A1_tb/dut/b0_reg_out
add wave -radix hex sim:/DSP48A1_tb/dut/b1_reg_out
add wave -radix hex sim:/DSP48A1_tb/dut/a1_reg_out
add wave -radix hex sim:/DSP48A1_tb/dut/u_mreg/Q
add wave -radix hex sim:/DSP48A1_tb/dut/opmode_use
add wave -radix hex sim:/DSP48A1_tb/dut/x_val
add wave -radix hex sim:/DSP48A1_tb/dut/z_val
add wave -radix hex sim:/DSP48A1_tb/dut/p_reg_out


run -all


wave zoom full
