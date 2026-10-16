module heap_permutation

import core:c

const max_length = 7
fn put_i32(mut output &u8, offset int, value i32) { bits:=u32(value);for b in 0..4{unsafe{output[offset+b]=u8(bits>>(8*b))}} }
fn generate(mut values []i32, n int, k int, mut output &u8, mut rows int) {
	if k==1 { start:=rows*n*4;for j in 0..n{put_i32(mut output,start+j*4,values[j])};rows++;return }
	for i in 0..k { swap_index:=i;if k%2!=0{swap_index=0};tmp:=values[swap_index];values[swap_index]=values[k-1];values[k-1]=tmp;generate(mut values,n,k-1,mut output,mut rows) }
}
@[export: 'heap_permutation']
pub fn heap_permutation(input &i64,length usize,mut output &u8,capacity usize) i64 {
	if unsafe{input==nil}||length<1||length>max_length+1{return -1}
	unsafe { n_value:=input[0];if n_value<0||n_value>max_length||length!=usize(n_value+1){return -1};n:=int(n_value);mut values:=[max_length]i32{}
		for i in 0..n{v:=input[i+1];if v< -2147483648||v>2147483647{return -1};values[i]=i32(v)}
		mut permutations:=1;for factor in 2..n+1{permutations*=factor};required:=permutations*n*4
		if capacity<required||(required!=0&&unsafe{output==nil}){return -2};if n==0{return 1}
		mut rows:=0;mut dynamic:=values[..];generate(mut dynamic,n,n,mut output,mut rows);return i64(rows)
	}
}
