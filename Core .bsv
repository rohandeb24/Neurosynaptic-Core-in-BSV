package Core; 
import FIFOF ::*;
import Vector::*;

typedef struct {
Int#(8) add;
Int#(8) time_step;
Bit#(1) last_spike;
} Input_spike deriving(Bits, Eq);

typedef struct {
Int#(8) add;
Int#(8) time_step;
}Out_spike deriving(Bits, Eq);

interface Core;
   method Action load_spike(Int#(8) timestep, Int#(8) add, Bit#(1) last);
   method ActionValue#(Out_spike) out();
endinterface

module mkCore#(Int#(8) n,Int#(8) pow,Bit#(1) sy[],Int#(8) w[],Int#(8) ty[],Int#(8) th)(Core);
   
   Vector#(256,Reg#(Bit#(1))) synapse <- replicateM( mkRegU );
   Vector#(16,Reg#(Int#(8))) potential <- replicateM( mkReg(0) );
   Vector#(16,Reg#(Int#(8))) g <- replicateM( mkRegU );
   Vector#(256,Reg#(Int#(8))) weight <- replicateM( mkRegU );
   Vector#(16,Reg#(Int#(8))) threshold <- replicateM( mkReg(th) );
   
   FIFOF#(Input_spike) buffer <- mkFIFOF;
   
   FIFOF#(Out_spike) out_buf <- mkFIFOF;

   Reg#(Int#(8)) counter <- mkReg(0);
   Reg#(Int#(8)) counter2 <- mkReg(0);
   Reg#(Int#(4)) state <- mkReg(0);
   Reg#(int) step <- mkReg(0);


   Int#(16) n_sq=zeroExtend(n)<<pow;   
   Int#(16) n_w=zeroExtend(n)<<2; 

   rule init ( step == 0 );
      for (Int#(16) i=0; i<n_sq; i=i+1)begin
            synapse[i]<=sy[i];
      end
      for (Int#(16) i=0; i<n_w; i=i+1)begin
            weight[i]<=w[i];
      end
      for (Int#(8) i=0; i<n; i=i+1)
         g[i] <= ty[i];
      step <= step + 1;
   endrule

 
   
   rule process_spike(state==0 && buffer.notEmpty);  
      state<=1;
      counter<=0;
   endrule
  
   for (Int#(8) i=0; i<n; i=i+1) begin
      rule integrate (state==1 && counter==i);
         Input_spike spike=buffer.first;
      	 Int#(8) row=spike.add;
      	 Int#(8) index=row<<pow;
         if (synapse[index+i]==1)
            begin
               Int#(8) w=weight[(i<<2)+g[row]];
               potential[i]<=potential[i]+w;
            end
         if (i==n-1) 
            begin
               counter<=0;
	           if(spike.last_spike==1) 
                  begin
                     state<=2;
	              end
               else 
                  begin
                     buffer.deq;
                  end
            end
         else counter <= counter+1;
      endrule
   end
  
   
   for (Int#(8) i=0; i<n; i=i+1) begin
      rule compare (state==2 && counter2==i);
	     if(potential[i]>threshold[i]) 
            begin
               Input_spike spike=buffer.first;
               potential[i]<=0;
               Out_spike out;
               out.add=i;
               out.time_step= spike.time_step;
               out_buf.enq(out);
	        end
	     if(i==n-1) 
            begin
	           state<=0;
               buffer.deq;
               counter2<=0;
            end
         else counter2 <= counter2+1;
      endrule
   end
   
   
   
   method Action load_spike(time_step,row,last);
     Input_spike spike;
     spike.add=row;
     spike.time_step=time_step;
     spike.last_spike=last;
     buffer.enq(spike);
   endmethod
   
   method ActionValue#(Out_spike) out();
      out_buf.deq;
      return out_buf.first;
   endmethod
   
endmodule: mkCore
        
endpackage: Core
