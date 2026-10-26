module fast_subset_convolution

const modulus = i64(998244353)

fn rank_of(mask int) int {
	mut r:=0
	mut x:=mask
	for x>0 { r+=x&1; x>>=1 }
	return r
}
fn put_i64_le(mut output &u8,offset int,value i64) {
	mut bits:=u64(value)
	for b in 0..8 { unsafe { output[offset+b]=u8(bits&255) }; bits>>=8 }
}

@[export: 'fast_subset_convolution']
pub fn fast_subset_convolution(input &i64,length usize,mut output &u8,capacity usize) i64 {
	if unsafe { input==nil }||length<3||length>33{return -1}
	unsafe {
		n64:=input[0];if n64<0||n64>4{return -1}
		n:=int(n64);size:=1<<n;if length!=usize(1+2*size){return -1}
		for i in 0..2*size {if input[1+i]<0||input[1+i]>=modulus{return -1}}
		mut f:=[5][16]i64{};mut g:=[5][16]i64{};mut h:=[5][16]i64{}
		for s in 0..size {r:=rank_of(s);f[r][s]=input[1+s];g[r][s]=input[1+size+s]}
		for bit in 0..n {for s in 0..size {if s&(1<<bit)!=0 {other:=s^(1<<bit);for r in 0..n+1 {f[r][s]=(f[r][s]+f[r][other])%modulus;g[r][s]=(g[r][s]+g[r][other])%modulus}}}}
		for s in 0..size {for r in 0..n+1 {mut sum:=i64(0);for i in 0..r+1 {sum=(sum+f[i][s]*g[r-i][s])%modulus};h[r][s]=sum}}
		for bit in 0..n {for s in 0..size {if s&(1<<bit)!=0 {other:=s^(1<<bit);for r in 0..n+1 {h[r][s]=(h[r][s]-h[r][other]+modulus)%modulus}}}}
		required:=size*8;if capacity<usize(required)||unsafe{output==nil}{return -2}
		for s in 0..size {put_i64_le(mut output,8*s,h[rank_of(s)][s])};return i64(required)
	}
}
