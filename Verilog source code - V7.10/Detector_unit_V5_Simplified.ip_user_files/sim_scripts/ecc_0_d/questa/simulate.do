onbreak {quit -f}
onerror {quit -f}

vsim  -lib xil_defaultlib ecc_0_d_opt

set NumericStdNoWarnings 1
set StdArithNoWarnings 1

do {wave.do}

view wave
view structure
view signals

do {ecc_0_d.udo}

run 1000ns

quit -force
