onbreak {quit -f}
onerror {quit -f}

vsim -voptargs="+acc"  -L xpm -L ecc_v2_0_16 -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip -lib xil_defaultlib xil_defaultlib.ecc_0_e xil_defaultlib.glbl

set NumericStdNoWarnings 1
set StdArithNoWarnings 1

do {wave.do}

view wave
view structure
view signals

do {ecc_0_e.udo}

run 1000ns

quit -force
