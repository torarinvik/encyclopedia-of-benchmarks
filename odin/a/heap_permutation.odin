package heap_permutation

import "core:c"

MAX_LENGTH :: 7
put_i32 :: proc "contextless" (output: [^]u8, offset: int, value: i32) { bits:=u32(value);for b:=0;b<4;b+=1{output[offset+b]=u8(bits>>(8*b))} }
generate :: proc "contextless" (values: [^]i32, n: int, k: int, output: [^]u8, rows: ^int) {
	if k==1 { start:=rows^ * n * 4;for j:=0;j<n;j+=1{put_i32(output,start+j*4,values[j])};rows^+=1;return }
	for i:=0;i<k;i+=1 { swap_index:=i;if k%2!=0{swap_index=0};tmp:=values[swap_index];values[swap_index]=values[k-1];values[k-1]=tmp;generate(values,n,k-1,output,rows) }
}
@(export)
heap_permutation :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input==nil||length<1||length>MAX_LENGTH+1 do return -1
	nv:=input[0];if nv<0||nv>MAX_LENGTH||length!=c.size_t(nv+1) do return -1
	n:=int(nv);var values:[MAX_LENGTH]i32
	for i:=0;i<n;i+=1{v:=input[i+1];if v< -2147483648||v>2147483647 do return -1;values[i]=i32(v)}
	permutations:=1;for f:=2;f<=n;f+=1{permutations*=f};required:=permutations*n*4
	if capacity<c.size_t(required)||(required!=0&&output==nil) do return -2;if n==0 do return 1
	rows:=0;generate(&values[0],n,n,output,&rows);return i64(rows)
}
