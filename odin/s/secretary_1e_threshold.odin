package secretary_1e_threshold
import "core:c"

MAX_N :: 16
MAX_INPUT :: 17
SAMPLE : [17]int = {0,0,0,1,1,1,2,2,2,3,3,4,4,4,5,5,5}

put64 :: proc(out:[^]u8,pos:int,value:i64){bits:=u64(value);for j:=0;j<8;j+=1{out[pos+j]=u8(bits&255);bits>>=8}}

@(export)
secretary_1e_threshold :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
    if input==nil||length<4||length>MAX_INPUT do return -1
    n64:=input[0]
    if n64<3||n64>MAX_N||length!=c.size_t(n64+1) do return -1
    n:=int(n64);seen:[MAX_N+1]bool={}
    for i:=0;i<n;i+=1{rank:=input[i+1];if rank<1||rank>n64||seen[int(rank)]{return -1};seen[int(rank)]=true}
    observed:=SAMPLE[n];threshold:=input[1]
    for i:=1;i<observed;i+=1{if input[i+1]>threshold{threshold=input[i+1]}}
    selected:=i64(-1)
    for i:=observed;i<n;i+=1{if input[i+1]>threshold{selected=i64(i);break}}
    if output==nil||capacity<c.size_t(8) do return -2
    staged:[8]u8={};put64(&staged[0],0,selected);for i:=0;i<8;i+=1{output[i]=staged[i]};return 8
}
