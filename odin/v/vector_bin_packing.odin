// Clean-room generalized vector First Fit bin-packing profile.
package vector_bin_packing
import "core:c"
MAX_N :: 32
MAX_D :: 4
MAX_INPUT :: 130
MAX_FIELDS :: 161
put :: proc(out:[^]u8,at:int,x:i64){bits:=u64(x);for b:=0;b<8;b+=1{out[at+b]=u8(bits&255);bits>>=8}}
@(export)
vector_bin_packing :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
 if input==nil||length<2||length>MAX_INPUT do return -1
 n64,d64:=input[0],input[1]
 if n64<1||n64>32||d64<1||d64>4||length!=c.size_t(2+int(n64*d64))do return -1
 n,d:=int(n64),int(d64)
 for i:=0;i<n*d;i+=1{if input[2+i]<0||input[2+i]>1000 do return -1}
 loads:[MAX_N*MAX_D]i64;assignment:[MAX_N]int;bins:=0
 for item:=0;item<n;item+=1{chosen:=bins;for b:=0;b<bins;b+=1{fits:=true;for q:=0;q<d;q+=1{if loads[b*MAX_D+q]+input[2+item*d+q]>1000{fits=false}};if fits{chosen=b;break}};if chosen==bins{bins+=1};assignment[item]=chosen;for q:=0;q<d;q+=1{loads[chosen*MAX_D+q]+=input[2+item*d+q]}}
 staged:[MAX_FIELDS]i64;count:=0;staged[count]=i64(bins);count+=1;for i:=0;i<n;i+=1{staged[count]=i64(assignment[i]);count+=1};for b:=0;b<bins;b+=1{for q:=0;q<d;q+=1{staged[count]=loads[b*MAX_D+q];count+=1}}
 if output==nil||capacity<c.size_t(8*count)do return -2;for i:=0;i<count;i+=1{put(output,8*i,staged[i])};return i64(8*count)
}
