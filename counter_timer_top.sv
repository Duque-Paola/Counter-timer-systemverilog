timeunit 1ns;
timeprecision 1ps;

module counter_timer_top (
    input  logic       MAX10_CLK1_50,  // PIN_P11
    input  logic [1:0] KEY,            // KEY0 (PIN_B8) -> Reset
    input  logic [9:0] SW,             // SW[0]=Enable, SW[1]=Load, SW[9:2]=Data
    output logic [9:0] LEDR            // LEDR[7:0]=Count, LEDR9=Max Tick
);

    counter_timer_duv u_duv (
        .clk       (MAX10_CLK1_50),
        .rst_n     (KEY[0]),
        .enable    (SW[0]),
        .load      (SW[1]),
        .data_in   (SW[9:2]),
        .count_out (LEDR[7:0]),
        .max_tick  (LEDR[9])
    );

    assign LEDR[8] = 1'b0;

endmodule