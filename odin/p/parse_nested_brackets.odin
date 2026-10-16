package parse_nested_brackets
import "core:c"
scan :: proc(s: [^]u8, lo, hi: int, h: ^u64) { depth:=0; begin:=0; for i:=lo;i<hi;i+=1 { if s[i]=='<' { if depth==0 do begin=i; depth+=1 } else if s[i]=='>' { depth-=1; if depth==0 { for j:=begin;j<=i;j+=1 { h^=(h^*257+u64(s[j])+1)%1_000_000_007 }; scan(s,begin+1,i,h) } } } }
@(export)
parse_nested_brackets :: proc "c" (v: [^]i64, n: c.size_t) -> i64 { if v==nil||n<1||n>129||v[0]<0||v[0]>128||n!=c.size_t(v[0]+1) do return -1; length:=int(v[0]); s:[128]u8; depth:=0; for i:=0;i<length;i+=1 { if v[i+1]<0||v[i+1]>127 do return -1; s[i]=u8(v[i+1]); if s[i]=='<' { depth+=1 } else if s[i]=='>' { depth-=1; if depth<0 do return -1 } }; if depth!=0 do return -1; h:=u64(0); scan(&s,0,length,&h); return i64(h) }

