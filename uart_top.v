module uart_top(

    input wire clk,
    input wire EnTx,
    input [7:0] data_in,
    input serial_in,
    output TxActive,
    output serial_out,
    output [7:0] data_out
);

uart_tx(
    .clk(clk), //internal clock
    .En_Tx(En_Tx),  //Enable Transmission
    .data_in(data_in),  //Raw Data Input
    .Tx_Active(TxActive), //Shows Tranmission in progress
    .serial_out(serial_out) //output data, send serially, 1 bit by 1 bit
);

uart_rx(
    .clk(clk),
    .serial_in(serial_in),
    .data_out(data_out)
);

endmodule
