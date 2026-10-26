package min_hash_k_mins
import "core:c"
MAX_INPUT :: 66
put64 :: proc(o:[^]u8,p:int,x:i64){b:=u64(x);for j:=0;j<8;j+=1{o[p+j]=u8(b&255);b>>=8}}
@(export)
min_hash_k_mins :: proc "c"(input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
 if input==nil||length<3||length>MAX_INPUT do return -1;nr:=input[0];kr:=input[1];if nr<1||nr>16||kr<1||kr>4||length!=c.size_t(2+nr*kr) do return -1;n:=int(nr);k:=int(kr)
 for i:=0;i<n*k;i+=1{if input[2+i]<0||input[2+i]>1000 do return -1};bytes:=8*k;if output==nil||capacity<c.size_t(bytes) do return -2
 for col:=0;col<k;col+=1{best:=0;for row:=1;row<n;row+=1{if input[2+row*k+col]<input[2+best*k+col]{best=row}};put64(output,8*col,i64(best))};return i64(bytes)
}
