transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

vlib work
vlib activehdl/xpm
vlib activehdl/sem_v4_1_15
vlib activehdl/xil_defaultlib

vmap xpm activehdl/xpm
vmap sem_v4_1_15 activehdl/sem_v4_1_15
vmap xil_defaultlib activehdl/xil_defaultlib

vlog -work xpm  -sv2k12 -l xpm -l sem_v4_1_15 -l xil_defaultlib \
"C:/Apps/Xilinx/Vivado/2024.1/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"C:/Apps/Xilinx/Vivado/2024.1/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -93  \
"C:/Apps/Xilinx/Vivado/2024.1/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work sem_v4_1_15  -v2k5 -l xpm -l sem_v4_1_15 -l xil_defaultlib \
"../../../ipstatic/hdl/sem_v4_1_vl_rfs.v" \

vlog -work xil_defaultlib  -v2k5 -l xpm -l sem_v4_1_15 -l xil_defaultlib \
"../../../../Detector_unit_V5_Simplified.gen/sources_1/ip/sem_0/sim/sem_0.v" \

vlog -work xil_defaultlib \
"glbl.v"

