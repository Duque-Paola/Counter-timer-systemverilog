timeunit 1ns;
timeprecision 1ps;

module tb_counter_timer_autocheck;

    localparam NUM_VECTORS = 14;

    logic       tb_clk;
    logic       tb_rst_n;
    logic       tb_enable;
    logic       tb_load;
    logic [7:0] tb_data_in;
    logic [7:0] tb_count_out;
    logic       tb_max_tick;

    // Estructura empaquetada: 1+1+1+8+8+1 = 20 bits
    typedef struct packed {
        logic       rst_n;
        logic       load;
        logic       enable;
        logic [7:0] data_in;
        logic [7:0] expected_count;
        logic       expected_max_tick;
    } test_vector_t;

    test_vector_t test_vectors[0:NUM_VECTORS-1];

    int error_count = 0;
    int vector_index = 0;

    // Instancia del DUV
    counter_timer_duv duv (
        .clk       (tb_clk),
        .rst_n     (tb_rst_n),
        .enable    (tb_enable),
        .load      (tb_load),
        .data_in   (tb_data_in),
        .count_out (tb_count_out),
        .max_tick  (tb_max_tick)
    );

    // Generador de Reloj de 50 MHz (Periodo = 20 ns: 10ns LOW, 10ns HIGH)
    initial begin
        tb_clk = 0;
        forever #10 tb_clk = ~tb_clk;
    end

    // Inicialización de vectores directamente en memoria (evita fallos de ruta)
    initial begin
        //           rst_n, load, enable, data_in, exp_count, exp_max_tick
        test_vectors[0]  = '{1'b0, 1'b0, 1'b0, 8'h00, 8'h00, 1'b0}; // Reset inicial
        test_vectors[1]  = '{1'b1, 1'b0, 1'b0, 8'h00, 8'h00, 1'b0}; // IDLE
        test_vectors[2]  = '{1'b1, 1'b1, 1'b0, 8'hA5, 8'hA5, 1'b0}; // LOAD 0xA5 (10100101)
        test_vectors[3]  = '{1'b1, 1'b1, 1'b0, 8'h5A, 8'h5A, 1'b0}; // LOAD 0x5A (01011010) Toggle
        test_vectors[4]  = '{1'b1, 1'b0, 1'b1, 8'h00, 8'h5B, 1'b0}; // COUNT (0x5A -> 0x5B)
        test_vectors[5]  = '{1'b1, 1'b0, 1'b0, 8'h00, 8'h5B, 1'b0}; // HOLD (IDLE)
        test_vectors[6]  = '{1'b1, 1'b1, 1'b0, 8'hFE, 8'hFE, 1'b0}; // LOAD 0xFE
        test_vectors[7]  = '{1'b1, 1'b0, 1'b1, 8'h00, 8'hFF, 1'b1}; // COUNT -> 0xFF (MAX_TICK activo)
        test_vectors[8]  = '{1'b1, 1'b0, 1'b1, 8'h00, 8'h00, 1'b0}; // Desborde a 0x00
        test_vectors[9]  = '{1'b1, 1'b0, 1'b1, 8'h00, 8'h01, 1'b0}; // COUNT -> 0x01
        test_vectors[10] = '{1'b1, 1'b1, 1'b0, 8'h00, 8'h00, 1'b0}; // LOAD 0x00
        test_vectors[11] = '{1'b1, 1'b1, 1'b0, 8'hFF, 8'hFF, 1'b0}; // LOAD 0xFF
        test_vectors[12] = '{1'b1, 1'b0, 1'b0, 8'h00, 8'hFF, 1'b0}; // HOLD con 0xFF
        test_vectors[13] = '{1'b0, 1'b0, 1'b0, 8'h00, 8'h00, 1'b0}; // Reset asíncrono final
    end

    // Proceso Principal de Simulación
    initial begin
        $display("==================================================================");
        $display(" INICIANDO TESTBENCH AUTO-COMPROBABLE CON GRÁFICAS ACTIVAS        ");
        $display("==================================================================");

        // Inicialización de señales del bus
        tb_rst_n   = 1'b0;
        tb_load    = 1'b0;
        tb_enable  = 1'b0;
        tb_data_in = 8'h00;

        #25; // 25 ns con Reset activo

        // Bucle de aplicación y muestreo
        for (vector_index = 0; vector_index < NUM_VECTORS; vector_index++) begin
            // 1. Inyectar estímulo en flanco negativo para evitar condiciones de carrera
            @(negedge tb_clk);
            tb_rst_n   = test_vectors[vector_index].rst_n;
            tb_load    = test_vectors[vector_index].load;
            tb_enable  = test_vectors[vector_index].enable;
            tb_data_in = test_vectors[vector_index].data_in;

            // 2. Esperar al siguiente flanco negativo para comprobar el resultado tras el posedge
            @(negedge tb_clk);

            // 3. Comprobación estricta
            if ((tb_count_out !== test_vectors[vector_index].expected_count) ||
                (tb_max_tick  !== test_vectors[vector_index].expected_max_tick)) begin
                $error("[FALLA VEC %0d] Obtenido: Count=0x%h, Tick=%b | Esperado: Count=0x%h, Tick=%b",
                       vector_index, tb_count_out, tb_max_tick,
                       test_vectors[vector_index].expected_count,
                       test_vectors[vector_index].expected_max_tick);
                error_count++;
            end else begin
                $display("[PASS VEC %0d] Count=0x%h | MaxTick=%b | Estado=3'b%03b",
                         vector_index, tb_count_out, tb_max_tick, duv.current_state);
            end
        end
		  
		  

        #40; // Tiempo extra para observar el comportamiento final en la onda
		  

        $display("==================================================================");
        if (error_count == 0)
            $display(" RESULTADO: TODAS LAS PRUEBAS PASARON EXITOSAMENTE (0 ERRORES)");
        else
            $display(" RESULTADO: SIMULACIÓN FALLÓ CON %0d ERRORES", error_count);
        $display("==================================================================");
		  // =========================================================================
    // NUEVAS PRUEBAS PARA ELEVAR COBERTURA (+80%)
    // =========================================================================

    // -------------------------------------------------------------------------
    // 1. MEJORA DE TOGGLES: Alternancia estricta de bus de datos (0x5A y 0xA5)
    // -------------------------------------------------------------------------
    $display("[TB-COV] Iniciando prueba de alternancia de bits (Toggles)...");
    
    @(negedge clk);
    data_in = 8'h5A;       // Carga patrón 01010101 (Fuerza cambios 0->1 y 1->0)
    send_trigger = 1'b1;
    @(negedge clk);
    send_trigger = 1'b0;
    
    // Esperar a que el transmisor vuelva a estar libre
    wait(tx_busy == 1'b0);
    
    @(negedge clk);
    data_in = 8'hA5;       // Carga patrón invertido 10101010
    send_trigger = 1'b1;
    @(negedge clk);
    send_trigger = 1'b0;
    
    wait(tx_busy == 1'b0);
    *Comprobación:* Todos los bits del bus de datos habrán conmutado en ambas direcciones.

    // -------------------------------------------------------------------------
    // 2. RECORRIDO DE LA FSM: Transiciones y Estados faltantes
    // -------------------------------------------------------------------------
    $display("[TB-COV] Forzando cambio de estados en FSM...");
    
    // Forzar recepción activa o respuesta de ACK si aplica
    @(negedge clk);
    rx_in = 1'b0;          // Dominante en la línea RX para simular inicio de trama entrante
    enable_rx = 1'b1;
    
    repeat (10) @(negedge clk);
    enable_rx = 1'b0;
    rx_in = 1'b1;          // Volver a estado Recesivo de reposo
    *Comprobación:* La FSM pasará por los estados de recepción/espera no alcanzados previamente.

    // -------------------------------------------------------------------------
    // 3. CONDICIONES DE BORDE Y ERROR: Cobertura de Branches y Statements
    // -------------------------------------------------------------------------
    $display("[TB-COV] Inyectando condiciones de error y reset...");
    
    // Provocar desbordamiento / error a mitad de una transmisión
    @(negedge clk);
    send_trigger = 1'b1;
    @(negedge clk);
    send_trigger = 1'b0;
    
    // Corrupción en la línea de bus mientras transmite
    repeat (3) @(negedge clk);
    rx_in = 1'b1;          // Ruido o desbalance de bus (Bit error / CRC error)
    
    // Reset asíncrono para evaluar ramas de recuperación defensiva
    repeat (5) @(negedge clk);
    rst_n = 1'b0;
    repeat (2) @(negedge clk);
    rst_n = 1'b1;
    *Comprobación:* Se ejecutarán los bloques defensivos dentro de los condicionales "if (error)" o "if (!rst_n)".

        $stop;
    end

endmodule