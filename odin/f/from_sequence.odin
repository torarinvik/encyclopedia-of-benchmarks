package from_sequence
import "core:c"
MAX_NODES :: 128
MAX_OUTPUT :: 3589
append_i64 :: proc(b: ^[MAX_OUTPUT]u8, start: int, x: i64) -> int {
    digits: [20]u8
    length := 0
    magnitude := if x < 0 { u64(-(x+1))+1 } else { u64(x) }
    for { digits[length]=u8('0'+magnitude%10);length+=1;magnitude/=10;if magnitude==0{break} }
    p:=start;b[p]=u8('<');p+=1;if x<0{b[p]=u8('-');p+=1}
    for length>0 {length-=1;b[p]=digits[length];p+=1}
    b[p]=u8('>');p+=1
    b[p]=u8(' ');b[p+1]=u8('-');b[p+2]=u8('-');b[p+3]=u8('-');b[p+4]=u8('>');b[p+5]=u8(' ')
    p+6
}
@(export)
from_sequence :: proc "c"(v:[^]i64,n:c.size_t,out:[^]u8,cap:c.size_t)->i64 {
    if v==nil||n<2||n>MAX_NODES+1 do return -1
    count:=v[0];if count<1||count>MAX_NODES||n!=c.size_t(count+1) do return -1
    mut b:[MAX_OUTPUT]u8{};mut p:=0
    for i:=i64(0);i<count;i+=1{p=append_i64(&b,p,v[i+1])}
    for i:=0;i<5;i+=1{end:=[5]u8{u8('<'),u8('E'),u8('N'),u8('D'),u8('>')};b[p+i]=end[i]};p+=5
    if out==nil||cap<c.size_t(p) do return -2
    for i:=0;i<p;i+=1{out[i]=b[i]}
    i64(p)
}
