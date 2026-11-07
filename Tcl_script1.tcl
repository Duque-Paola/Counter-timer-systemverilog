# ==============================================================================
# Script Tcl para Compilación, Simulación y Reporte de Cobertura
# Módulo: counter_timer (Testbench: tb_counter_timer_duv)
# ==============================================================================

# 1. Limpieza del entorno previo
if {[file exists work]} {
    vdel -all
}
vlib work
vmap work work

# 2. Compilación con cobertura
puts "==> Compilando todos los modulos del proyecto counter_timer_duv con recoleccion de cobertura..."
# Compilamos todos los archivos necesarios
#-----------------------------------------------------------------------------------------------Aquí abajo añade los nombre de tus archivos separados con un espacio así como los de mi modulo, si cambiaste el nombre de tu testbench principal, sustituye el mio
vlog +cover=sbecft counter_timer_duv.sv counter_timer_top.sv tb_counter_timer_autocheck.sv

#Aquí abajo también añade los nombres de tus modulos
if {[catch {vlog +cover=sbecft counter_timer_duv.sv counter_timer_top.sv tb_counter_timer_autocheck.sv
} err]} {
#-----------------------------------------------------------------------------------------------<
    puts "ERROR en compilacion: $err"
    return
}

# 3. Inicializar la simulación con cobertura (apuntando al testbench del Top)
puts "==> Cargando simulacion con soporte de cobertura..."
#-----------------------------------------------------------------------------------------------aquí abajo añade el nombre de tu testbench
vsim -coverage work.tb_counter_timer_autocheck
if {[catch {vsim -coverage work.tb_counter_timer_autocheck} err]} {
#-----------------------------------------------------------------------------------------------<
    puts "ERROR al cargar simulacion: $err"
    return
}

# 4. Ejecutar la simulación
puts "==> Ejecutando simulacion..."
run -all
#-----------------------------------------------------------------------------------------------A partir de aquí le configuras el nombre a los archivos de la verificacion para guardarlos
# 5. Guardar la base de datos de cobertura (UCDB)
puts "==> Guardando base de datos UCDB..."
coverage save counter_results.ucdb

# 6. Generar Reportes de Cobertura
puts "==> Generando reportes de cobertura..."

# Reporte detallado en formato TXT
coverage report -detail -output counter_timer_cobertura_reporte.txt

# Reporte HTML
coverage report -html -output covhtmlreport -details -assert -directive -code bcefst

puts "=============================================================================="
puts " Reporte de cobertura generado exitosamente:"
puts "   - Texto: cobertura_reporte.txt"
puts "   - HTML:  covhtmlreport/index.html"
puts "=============================================================================="

# Finalizar la simulación
# quit -f  <--- Dejamos comentado el quit para que no se cierre la ventana y puedas ver los resultados