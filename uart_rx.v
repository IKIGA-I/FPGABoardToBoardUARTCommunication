module uart_rx (
    input   clk,
    input   serial_in,
    output [7:0] data_out;
);

parameter IDLE                 = 3'b000;
parameter RECEIVE_START_BIT    = 3'b001;
parameter RECEIVE_DATA_BITS    = 3'b010;
parameter RECEIVE_STOP_BIT     = 3'b011;
parameter WAIT                 = 3'b100;

reg       Rx_Data_Reg1 = 1'b1;
reg       Rx_Data_Reg2 = 1'b1;

reg [7:0]   data_temp       = 0; //storing raw data here
reg [2:0]   state           = 0; //5 states
reg [8:0]   baudrate_count  = 0; //8 bits of data
reg [2:0]   bit_count       = 0; //8 bits of data

parameter clk_freq      = 50000000;  //50MHz internal clock
parameter baudrate      = 115200;    //baudrate used
parameter clks_per_bit  = clk_freq/baudrate;    

//Purpose: Double register the incoming data
//This allows it to be used in the UART Rx Clock Domain
//(It removes problems caused by metastability)
always @(posedge clk) 
    begin
        Rx_Data_Reg1 <= serial_in;
        Rx_Data_Reg2 <= Rx_Data_Reg1;
    end

always @(posedge clk)
    begin
        
        case(state)
            IDLE :
                begin
                    baudrate_count <= 0;
                    bit_count <= 0;

                    if (Rx_Data_Reg2 == 1'b0)   //Detect start bit
                        state <= RECEIVE_START_BIT;
                    else
                        state <= IDLE;
                end
            
            RECEIVE_START_BIT:
                begin
                    if (baudrate_count == (clks_per_bit-1)/2)//will sample from the middle of the start bit
                        begin
                            if(Rx_Data_Reg2 == 1'b0)
                            begin
                                baudrate_count <= 0; //reset counter, found the middle
                                state <= RECEIVE_DATA_BITS;
                            end
                            else
                                state <= IDLE;
                        end
                    else
                        begin
                            baudrate_count <= baudrate_count + 1;
                            state <= RECEIVE_START_BIT;
                        end
                end

            RECEIVE_DATA_BITS:
                begin
                    if(baudrate_count < clks_per_bit - 1) //Wait 1 cycle for start bit to finish transmitting
                        begin
                            baudrate_count <= baudrate_count + 1;
                            state <= RECEIVE_DATA_BITS;
                        end
                    else
                        begin
                            baudrate_count <= 0;
                            data_temp[bit_count] <= Rx_Data_Reg2;

                            if(bit_count < 7) //Make sure all 8 bits received
                                begin
                                    bit_count <= bit_count + 1;
                                    state <= RECEIVE_DATA_BITS;
                                end
                            else
                                begin
                                  bit_count <= 0;
                                  state <= RECEIVE_STOP_BIT;
                                end
                        end
                end

                //Receieve Stop bit: Stop bit = 1
                RECEIVE_STOP_BIT:
                    begin
                        if(baudrate_count < clks_per_bit-1)
                            begin
                                baudrate_count <= baudrate_count + 1;
                                state <= RECEIVE_STOP_BIT;
                            end
                        else
                            begin
                                baudrate_count <= 0;
                                state <= WAIT;
                            end
                    end

                WAIT:
                    begin
                        state <= IDLE;
                    end

                default:
                    state<= IDLE;

        endcase
    end
    assign data_out = data_temp;

endmodule          
                            