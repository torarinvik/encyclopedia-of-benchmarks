package lfsr
import "core:c"
MAX_TAPS :: 63
MAX_CLOCKS :: 256
feedback :: proc "contextless" (state:u64,input:[^]i64,count:int)->u64{bit:=u64(0);for i:=0;i<count;i+=1{bit^=(state>>u64(input[6+i]))&1};return bit}
step :: proc "contextless" (state:^u64,width:int,mask:u64,input:[^]i64,count:int)->u64{current:=state^;out:=(current>>u64(width-1))&1;state^=((current<<1)|feedback(current,input,count))&mask;return out}
put_i64 :: proc "contextless" (out:[^]u8,slot:int,value:i64){bits:=u64(value);for i:=0;i<8;i+=1{out[slot*8+i]=u8(bits>>u64(i*8))}}
@(export)
lfsr :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
 if input==nil||length<6||input[0]<1||input[0]>63||input[1]<0||input[1]>=input[0]||input[2]<0||input[2]>MAX_TAPS||input[3]<0||input[3]>MAX_CLOCKS||input[5]<0||input[5]>4194303 do return -1
 width:=int(input[0]);count:=int(input[2]);clocks:=int(input[3]);if int(length)!=6+count do return -1
 for i:=0;i<count;i+=1{if input[6+i]<0||input[6+i]>=i64(width) do return -1}
 key:=u64(input[4]);frame:=u64(input[5]);state:=u64(0);mask:=(u64(1)<<u64(width))-1
 for bit:=63;bit>=0;bit-=1{incoming:=((key>>u64(bit))&1)^feedback(state,input,count);state=((state<<1)|incoming)&mask}
 for bit:=21;bit>=0;bit-=1{incoming:=((frame>>u64(bit))&1)^feedback(state,input,count);state=((state<<1)|incoming)&mask}
 bytes:=(clocks+2)*8;if output==nil||int(capacity)<bytes do return -2;put_i64(output,0,i64(clocks));for i:=0;i<clocks;i+=1{put_i64(output,1+i,i64(step(&state,width,mask,input,count)))};put_i64(output,1+clocks,i64(state));return i64(bytes)
}
