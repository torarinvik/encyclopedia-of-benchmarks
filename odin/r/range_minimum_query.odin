package range_minimum_query
import "core:c"
put_i64_le :: proc "contextless" (value:i64, output:[^]u8, offset:usize) { bits:=u64(value);for b:=0;b<8;b+=1{output[offset+b]=u8(bits>>u64(8*b))} }
@(export)
range_minimum_query :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64 {
    if input==nil||length<4 do return -1
    if input[0]<1||input[0]>64 do return -1
    n:=usize(input[0]);qp:=1+n
    if length<=qp||input[qp]<1||input[qp]>64 do return -1
    q:=usize(input[qp]);if length!=qp+1+2*q do return -1
    values:[64]i64
    for i:usize=0;i<n;i+=1{values[i]=input[1+i];if values[i]<-1000||values[i]>1000 do return -1}
    if capacity<q*8||(q>0&&output==nil) do return -2
    table:[7][64]usize
    for i:usize=0;i<n;i+=1{table[0][i]=i}
    for k:usize=1;(1<<k)<=n;k+=1{width:=1<<k;half:=width>>1;for i:usize=0;i+width<=n;i+=1{a:=table[k-1][i];b:=table[k-1][i+half];table[k][i]=if values[a]<values[b]{a}else{b}}}
    invalid:i64=-9223372036854775807-1
    for j:usize=0;j<q;j+=1{left:=input[qp+1+2*j];right:=input[qp+2+2*j];answer:=invalid
        if left>=0&&right>left&&right<=i64(n){l:=usize(left);r:=usize(right);span:=r-l;level:usize=0;for (1<<(level+1))<=span{level+=1};width:=1<<level;a:=table[level][l];b:=table[level][r-width];answer=if values[a]<values[b]{values[a]}else{values[b]}}
        put_i64_le(answer,output,j*8)}
    return i64(q*8)
}
