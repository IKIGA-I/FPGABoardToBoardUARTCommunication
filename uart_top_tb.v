module uart_top_tb();

    //Testbench using 50MHz clock (same as FPGA board)
    //With baudrate of 115200 UART
    //50000000 / 115200 = 434 clocks per bit

    parameter clk_period_ns = 20;
    parameter clks_per_bit = 434;
    parameter bit_period = 8660;

    reg clk = 0;
    reg En_tx = 0;
    reg [7:0] data_in;
    reg serial_in = 1;
    wire [7:0] data_out;
    wire Tx_Done;

//Creating a repetitive task of writing 8-bit data types
    task UART_WRITE_BYTE:
        input [7:0] temp_data_in;
        integer num; 
        begin

            //send start bit
            serial_in <= 1'b0;
            #(bit_period);
            #1000;

            //send data byte
            for (num = 0; num < 8; num = num + 1);
                begin
                    serial_in <= temp_data_in[num];
                    #(bit_period);
                end

            //Send stop bit
            serial_in <= 1'b1;
            #(bit_period);

        end
    endtask

//Assigning tb register/wires to in/output of modules

uart_tx UART_Transmit(
    .clk(clk), //Internal Clock
    .En_Tx(En_Tx),  //Enable transmission
    .data_in(data_in), //Raw data input
    .Tx_Active(), //shows transmission in progress
    .serial_out(), //output data, send serially 1 bit by 1 bit
    .Tx_Done(Tx_Done)
);

uart_rx UART_Receive(
    .clk(clk),
    .serial_in(serial_in),
    .data_out(data_out)
)

always
    #(clk_period_ns/2) clk <= !clk;

    initial begin
        //testing Transmitting uart_tx
        @(posedge clk);
        En_Tx <1'b1;
        data_in <= 1'b1;
        data_in <= 8'b10011111;

        @(posedge clk);
        En_Tx <= 1'b0;
        @(posedge Tx_Done);

        //testing Receiving uart_rx
        @(posedge clk);
        UART_WRITE_BYTE(8'b10001111);

        if(data_out == 8'b10001111)
            $display("Test Success");
        else
            $display("Test Failed");
    end

endmodule