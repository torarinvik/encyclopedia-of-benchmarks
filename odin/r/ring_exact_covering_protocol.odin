package ring_exact_covering_protocol
import "core:c"

SCALE :: 16
MAX_N :: 12
MAX_STEPS :: 64
MAX_INPUT :: 79
MAX_OUTPUT :: 208
put_i64 :: proc(out:[^]u8,offset:int,value:i64){bits:=u64(value);for b:=0;b<8;b+=1{out[offset+b]=u8(bits&255);bits>>=8}}

@(export)
ring_exact_covering_protocol :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64 {
    if input==nil||length<3||length>MAX_INPUT||input[0]<2||input[0]>MAX_N||input[2]<0||input[2]>MAX_STEPS{return -1}
    n:=int(input[0]);steps:=int(input[2]);if length!=c.size_t(3+n+steps){return -1};circumference:=i64(SCALE*n);visibility:=input[1]
    if visibility<2*SCALE||visibility>circumference{return -1}
    position:[MAX_N]i64;for i:=0;i<n;i+=1{position[i]=input[3+i];if position[i]<0||position[i]>=circumference||(i>0&&position[i-1]>=position[i]){return -1}}
    for j:=0;j<steps;j+=1{if input[3+n+j]<0||input[3+n+j]>=i64(n){return -1}}
    moved:i64=0;for j:=0;j<steps;j+=1{i:=int(input[3+n+j]);next:=(i+1)%n;gap:=(position[next]-position[i]+circumference)%circumference;distance:=i64(0);if gap>visibility{distance=SCALE}else if gap>SCALE{distance=gap-SCALE};if distance!=0{position[i]=(position[i]+distance)%circumference;moved+=1}}
    words:=2+2*n;bytes:=8*words;if output==nil||capacity<c.size_t(bytes){return -2}
    result:[2+2*MAX_N]i64;result[0]=i64(n);result[1]=moved;for i:=0;i<n;i+=1{result[2+i]=position[i];result[2+n+i]=(position[(i+1)%n]-position[i]+circumference)%circumference}
    staged:[MAX_OUTPUT]u8;for i:=0;i<words;i+=1{put_i64(&staged[0],8*i,result[i])};for i:=0;i<bytes;i+=1{output[i]=staged[i]};return i64(bytes)
}
