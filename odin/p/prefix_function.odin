package prefix_function
import "core:c"
@(export)
prefix_function :: proc "c" (v:[^]i64,n:c.size_t,out:[^]u8,cap:c.size_t)->i64{if v==nil||n<1||n>4097||v[0]<0||v[0]>4096||n!=c.size_t(v[0]+1) do return -1;len:=int(v[0]);for i:=0;i<len;i+=1{if v[i+1]<0||v[i+1]>127 do return -1};bytes:=len*4;if c.size_t(bytes)>cap||(bytes>0&&out==nil) do return -2;pi:[4096]int;for i:=1;i<len;i+=1{j:=pi[i-1];for j>0&&v[i+1]!=v[j+1]{j=pi[j-1]};if v[i+1]==v[j+1]{j+=1};pi[i]=j};for i:=0;i<len;i+=1{x:=u32(pi[i]);for k:=0;k<4;k+=1{out[4*i+k]=u8((x>>(8*k))&255)}};return i64(bytes)}
