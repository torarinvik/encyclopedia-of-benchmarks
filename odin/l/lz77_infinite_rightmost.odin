package lz77_infinite_rightmost
import "core:c"
Max_Text :: 64
Max_Input :: 66
Max_Output :: 1536
put64 :: proc(out:[^]u8,at:int,value:i64){bits:=u64(value);for i in 0..<8{out[at+i]=u8(bits&255);bits>>=8}}
@(export)
lz77_infinite_rightmost :: proc "c"(input:[^]i64,len:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
    if input==nil||len<1||len>Max_Input do return -1
    n64:=input[0];if n64<0||n64>Max_Text do return -1
    n:=int(n64);if len!=c.size_t(n+1) do return -1
    for i in 0..<n{if input[i+1]<32||input[i+1]>126 do return -1}
    staged:[Max_Output]u8;tokens:=0;q:=0
    for i in 0..<Max_Output{staged[i]=0}
    for q<n{
        bl:=0;bp:=0;found:=false
        for p in 0..<q{l:=0;for q+l<n&&input[p+l+1]==input[q+l+1]{l+=1};if l>bl||(l==bl&&l>0&&(!found||p>bp)){bl=l;bp=p;found=true}}
        source_pos:i64=0;if found{source_pos=i64(bp)}
        np:=q+bl;ch:i64=0;if np<n{ch=input[np+1]};at:=tokens*24
        put64(&staged[0],at,source_pos);put64(&staged[0],at+8,i64(bl));put64(&staged[0],at+16,ch);tokens+=1
        if ch!=0{q=np+1}else{q=np}
    }
    bytes:=tokens*24;if output==nil||capacity<c.size_t(bytes) do return -2
    for i in 0..<bytes{output[i]=staged[i]};return i64(bytes)
}
