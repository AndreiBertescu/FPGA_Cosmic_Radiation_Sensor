transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

asim +access +r +m+ecc_0_e  -L xpm -L ecc_v2_0_16 -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.ecc_0_e xil_defaultlib.glbl

do {ecc_0_e.udo}

run 1000ns

endsim

quit -force
