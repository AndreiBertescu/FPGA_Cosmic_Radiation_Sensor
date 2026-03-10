vlib questa_lib/work
vlib questa_lib/msim

vlib questa_lib/msim/xpm
vlib questa_lib/msim/sem_v4_1_15
vlib questa_lib/msim/xil_defaultlib

vmap xpm questa_lib/msim/xpm
vmap sem_v4_1_15 questa_lib/msim/sem_v4_1_15
vmap xil_defaultlib questa_lib/msim/xil_defaultlib

vlog -work xpm  -incr -mfcu  -sv \
"C:/Apps/Xilinx/Vivado/2024.1/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"C:/Apps/Xilinx/Vivado/2024.1/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm  -93  \
"C:/Apps/Xilinx/Vivado/2024.1/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work sem_v4_1_15  -incr -mfcu  \
"../../../ipstatic/hdl/sem_v4_1_vl_rfs.v" \

vlog -work xil_defaultlib  -incr -mfcu  \
"../../../../Detector_unit_V5_Simplified.gen/sources_1/ip/sem_0/sim/sem_0.v" \

vlog -work xil_defaultlib \
"glbl.v"

