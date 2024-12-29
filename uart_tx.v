module uart_tx(
    input clk, //internal clock
    input En_Tx, //enable trasmission
    input [7:0] data_in, //raw data input
    output reg Tx_Active, //shows transmission in progress
    output reg serial_out //output data, send serially, 1 bit by bit
    );

reg [7:0]   data_temp       = 0; //storing raw data here
reg [2:0]   state           = 0; //5 states
reg [8:0]   baudrate_count  = 0; //8 bits of data
reg [2:0]   bit_count       = 0; //8 bits of data

parameter IDLE              = 3'b000;
parameter SEND_START_BIT    = 3'b001;
parameter SEND_DATA_BITS    = 3'b010;
parameter SEND_STOP_BIT     = 3'b011;
parameter WAIT              = 3'b100;

parameter clk_freq          = 50000000; //50MHz internal clock
parameter baudrate          = 115200;   //my baudrate
parameter clks_per_bit      = clk_freq/baudrate;

always @(posedge clk)
    begin
        
        case (state)

            IDLE :
                begin 
                    serial_out <= 1'b1;  //output is 1 when idle
                    baudrate_count <= 0; 
                    bit_count <= 0;
                    if (En_Tx == 1'b1) //when enable transmit is high/on
                        begin
                            Tx_Active <= 1'b1;
                            data_temp <= data_in; //load raw data into data_temp
                            state <= SEND_START_BIT;
                        end
                        else
                        state <= IDLE;
                end
            
            SEND_START_BIT :
                begin
                    serial_out <= 1'b0; //send out start bit which is 0

                    if (baudrate_count < clks_per_bit-1) //wait 1 cycle for start bit to finish
                        begin                            //1 cycle means count finish my clks_per_bit
                            baudrate_count <= baudrate_count + 1;
                            state <= SEND_START_BIT;
                        end
                        else
                            begin 
                                baudrate_count <= 0;
                                state <= SEND_DATA_BITS;
                            end
                end

            //wait clks_per_bit-1 clock cycles for data bits to finish
            SEND_DATA_BITS :
                begin
                    serial_out <= data_temp[bit_count]; //send out data serially, start with data_temp[0]

                    if (baudrate_count < clks_per_bit - 1) 
                        begin
                            baudrate_count <= baudrate_count + 1;
                            state <= SEND_DATA_BITS;
                        end
                    else
                        begin
                            baudrate_count <= baudrate_count + 1;
                            state <= SEND_DATA_BITS;
                        end
                    else 
                        begin
                            baudrate_count <= 0; //reset to 0 for new cycle

                            //Checking if all bits have been sent
                            if (bit_count < 7) //we have 8 bits, so this is to ensure we finish sending out all bits
                                begin
                                    bit_count <= bit_count + 1;
                                    state <= SEND_DATA_BITS;
                                end
                            else //If all bits have been sent
                                begin
                                    bit_count <= 0;
                                    state <= SEND_STOP_BIT;
                                end
                        end
                end

            SEND_STOP_BIT :
                begin
                    serial_out <= 1'b1; //send out stop bit which is 1

                    //wait clks_per_bit-1 clock cycles for stop bit to finish
                    if (baudrate_count < clks_per_bit-1)
                        begin
                            baudrate_count <= baudrate_count++;
                            state <= SEND_STOP_BIT;
                        end
                    else
                        begin
                            baudrate_count <= 0;
                            state <= WAIT;
                            Tx_Active <= 1'b0;
                        end
                end

            WAIT :
                begin
                    state <= IDLE;
                end
        endcase
    end

endmodule

   