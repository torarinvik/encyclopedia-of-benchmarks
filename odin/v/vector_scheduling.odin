// Clean-room explicit-choice profile of randomized vector scheduling.
package vector_scheduling
import "core:c"
MAX_N :: 16
MAX_M :: 8
MAX_D :: 4
MAX_INPUT :: 83
MAX_FIELDS :: 35
put :: proc(out:[^]u8,at:int,x:i64){bits:=u64(x);for b:=0;b<8;b+=1{out[at+b]=u8(bits&255);bits>>=8}}
@(export)
vector_scheduling :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
 if input==nil||length<3||length>MAX_INPUT do return -1
 n64,m64,d64:=input[0],input[1],input[2]
 if n64<1||n64>16||m64<1||m64>8||d64<1||d64>4||length!=c.size_t(3+int(n64)+int(n64*d64))do return -1
 n,m,d:=int(n64),int(m64),int(d64)
 for j:=0;j<n;j+=1{if input[3+j]<0||input[3+j]>=m64 do return -1}
 for i:=0;i<n*d;i+=1{if input[3+n+i]<0||input[3+n+i]>1000 do return -1}
 loads:[MAX_M*MAX_D]i64
 for j:=0;j<n;j+=1{machine:=int(input[3+j]);for q:=0;q<d;q+=1{loads[machine*MAX_D+q]+=input[3+n+j*d+q]}}
 span:=i64(0);for i:=0;i<m;i+=1{for q:=0;q<d;q+=1{if loads[i*MAX_D+q]>span{span=loads[i*MAX_D+q]}}}
 staged:[MAX_FIELDS]i64;count:=0;staged[count]=m64;count+=1;staged[count]=d64;count+=1;staged[count]=span;count+=1;for i:=0;i<m;i+=1{for q:=0;q<d;q+=1{staged[count]=loads[i*MAX_D+q];count+=1}}
 if output==nil||capacity<c.size_t(8*count) do return -2
 for i:=0;i<count;i+=1{put(output,8*i,staged[i])};return i64(8*count)
}
