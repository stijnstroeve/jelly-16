rm -rf work &&
nvc --std=2008 --work=work -a src/jelly_pkg.vhd src/alu.vhd src/cond_matcher.vhd \
    src/decoder.vhd src/pc.vhd src/regfile.vhd src/sram.vhd src/sram_async.vhd \
    src/status_reg.vhd src/jelly_16.vhd testbenches/*.vhd &&
nvc --std=2008 --work=work -e $1 -r --stop-time=1us \
    --wave=output/fib.fst --format=fst --dump-arrays