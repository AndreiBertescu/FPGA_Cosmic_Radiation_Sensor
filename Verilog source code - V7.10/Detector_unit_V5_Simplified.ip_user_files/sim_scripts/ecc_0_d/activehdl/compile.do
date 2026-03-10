transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

vlib work
vlib activehdl/xpm
vlib activehdl/ecc_v2_0_16
vlib activehdl/xil_defaultlib

vmap xpm activehdl/xpm
vmap ecc_v2_0_16 activehdl/ecc_v2_0_16
vmap xil_defaultlib activehdl/xil_defaultlib

vlog -work xpm  -sv2k12 -l xpm -l ecc_v2_0_16 -l xil_defaultlib \
"C:/Apps/Xilinx/Vivado/2024.1/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"C:/Apps/Xilinx/Vivado/2024.1/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -93  \
"C:/Apps/Xilinx/Vivado/2024.1/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work ecc_v2_0_16  -v2k5 -l xpm -l ecc_v2_0_16 -l xil_defaultlib \
"../../../ipstatic/hdl/ecc_v2_0_vl_rfs.v" \

vlog -work xil_defaultlib  -v2k5 -l xpm -l ecc_v2_0_16 -l xil_defaultlib \
"../../../../Detector_unit_V5_Simplified.gen/sources_1/ip/ecc_0_d/sim/ecc_0_d.v" \

vlog -work xil_defaultlib \
"glbl.v"

