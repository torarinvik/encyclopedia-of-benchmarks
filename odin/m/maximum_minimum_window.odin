package maximum_minimum_window
import "core:c"
store_i64_le :: proc "contextless" (out: [^]u8, pos: int, value: i64) { bits:=transmute(u64)value;for b:=0;b<8;b+=1{out[pos+b]=u8(bits>>u64(8*b))} }
@(export)
maximum_minimum_window :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64 {
	if input==nil||length<2 do return -2
	n0:=input[0];if n0<1||n0>256||length!=c.size_t(n0+1) do return -2
	n:=int(n0);for i:=0;i<n;i+=1{if input[i+1]<0||input[i+1]>1_000_000 do return -2};if output==nil||capacity<c.size_t(n*8) do return -3
	var stack:[256]int;var left:[256]int;var right:[256]int;var ans:[257]i64;top:=0
	for i:=0;i<n;i+=1{for top>0&&input[stack[top-1]+1]>=input[i+1]{top-=1};left[i]=-1;if top>0{left[i]=stack[top-1]};stack[top]=i;top+=1}
	top=0;for ii:=n;ii>0;{ii-=1;for top>0&&input[stack[top-1]+1]>=input[ii+1]{top-=1};right[ii]=n;if top>0{right[ii]=stack[top-1]};stack[top]=ii;top+=1}
	for i:=0;i<n;i+=1{size:=right[i]-left[i]-1;if ans[size]<input[i+1]{ans[size]=input[i+1]}}
	for k:=n;k>1;{k-=1;if ans[k-1]<ans[k]{ans[k-1]=ans[k]}}
	for i:=1;i<=n;i+=1{store_i64_le(output,(i-1)*8,ans[i])};return i64(n)
}
