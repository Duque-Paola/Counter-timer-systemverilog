if {[file exists work]} { vdel -all -lib work }
vlib work
vmap work work

# En lugar de los ../ hay que poner el directorio completo
# Por ejemplo D:/Electronic_Design/Verilog_Labs/Verificacion_FPGA/counter_timer_duv/counter_timer_duv.sv
vlog -sv -stats=none C:/Users/pao_l/Documents/counter_timer_duv/counter_timer_duv.sv
vlog -sv -stats=none C:/Users/pao_l/Documents/counter_timer_duv/tb_counter_timer_autocheck.sv

vsim -t 1ps -voptargs="+acc" work.tb_counter_timer_autocheck

add wave -noupdate -divider {RELOJ Y RESET}
add wave -noupdate -format Logic -color Yellow /tb_counter_timer_autocheck/tb_clk
add wave -noupdate -format Logic -color Red    /tb_counter_timer_autocheck/tb_rst_n

add wave -noupdate -divider {SEÑALES DE CONTROL}
add wave -noupdate -format Logic /tb_counter_timer_autocheck/tb_enable
add wave -noupdate -format Logic /tb_counter_timer_autocheck/tb_load
add wave -noupdate -format Hex   /tb_counter_timer_autocheck/tb_data_in

add wave -noupdate -divider {SALIDAS Y COMPROBACIÓN}
add wave -noupdate -format Hex   -color Cyan   /tb_counter_timer_autocheck/tb_count_out
add wave -noupdate -format Logic -color Green  /tb_counter_timer_autocheck/tb_max_tick
add wave -noupdate -format Unsigned /tb_counter_timer_autocheck/error_count

run -all
wave zoomfull

