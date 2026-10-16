package swap_nodes
import "core:c"
put64 :: proc "contextless" (out:[^]u8,pos:^int,x:i64){v:=u64(x);for j:=0;j<8;j+=1{out[pos^]=u8(v&255);pos^+=1;v>>=8}}
@(export)
swap_nodes :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64 {
 if input==nil||length<3 do return -1;n0:=input[0];if n0<0||n0>64||length!=c.size_t(n0+3) do return -1;n:=int(n0)
 for i:=0;i<n;i+=1{if input[1+i]< -2147483648||input[1+i]>2147483647 do return -1};a:=input[1+n];b:=input[2+n];if a< -2147483648||a>2147483647||b< -2147483648||b>2147483647 do return -1
 need:=8+8*n;if output==nil||capacity<c.size_t(need) do return -2;ia:=n;ib:=n;if a!=b{for i:=0;i<n;i+=1{if ia==n&&input[1+i]==a do ia=i;if ib==n&&input[1+i]==b do ib=i}}
 pos:=0;put64(output,&pos,n0);for i:=0;i<n;i+=1{x:=input[1+i];if ia<n&&ib<n{if i==ia do x=b else if i==ib do x=a};put64(output,&pos,x)};return i64(pos)
}
