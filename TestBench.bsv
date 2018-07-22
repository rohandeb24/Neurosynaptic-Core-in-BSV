package TestBench;
import RegFile::*;
import FIFOF::*;
import Core::*;
import Vector::*;



(* synthesize *)
module mkTestBench(Empty);
   Reg#(Bit#(7)) state <- mkReg(0);
   Reg#(Bit#(6)) i <- mkReg(0);
   Reg#(int) cl <- mkReg(0);
   Bit#(1) sy[64]={0,1,1,0,1,0,0,1, 1,0,0,0,1,0,1,1, 0,0,1,1,1,0,0,0, 1,1,0,1,0,1,1,0, 1,0,1,0,0,0,0,1, 1,1,1,1,0,0,0,0, 0,0,1,0,1,1,1,0, 1,1,1,0,0,1,0,1};
   Int#(8) w[32]={7,5,-6,0, 2,10,5,0, -6,-9,4,0, 1,11,-7,0, 4,5,8,0, -8,5,2,0, -2,-5,-1,0, 6,-13,2,0};
   Int#(8) ty[8]= {1,2,0,1,0,2,1,1};
   

   Core core<-mkCore (8,3,sy,w,ty,10);
   
   RegFile#( Bit#(6), Bit#(16) ) s <- mkRegFileFullLoad ("Input.hex") ;
   
   rule process(state!=64);
        Int#(16) c=unpack(s.sub(i));
        Bit#(1) last=truncate(pack(c)-((pack(c)>>1)<<1));
        Int#(8)  row=truncate((c>>1)-((c>>4)<<3));
        Int#(8) time_step=truncate(c>>4);
        core.load_spike(time_step,row,last);
        state<=state+1;
        i<=i+1;
   endrule
   rule out;
        let t<-core.out;
        $display("%d| %d",t.time_step,t.add);
   endrule
endmodule
endpackage
