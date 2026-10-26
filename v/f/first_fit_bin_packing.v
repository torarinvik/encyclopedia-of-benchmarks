module first_fit_bin_packing
fn put_i64_le(mut out &u8,offset int,value i64){mut u:=u64(value);for b in 0..8{unsafe{out[offset+b]=u8(u&255)};u>>=8}}
@[export:'first_fit_bin_packing']
pub fn first_fit_bin_packing(input &i64,length usize,mut output &u8,capacity usize)i64{
	if unsafe{input==nil}||length<1||length>65{return -1}
	unsafe{
		n64:=input[0];if n64<0||n64>64{return -1};n:=int(n64);if length!=usize(1+n){return -1}
		for i in 0..n{if input[i+1]<1||input[i+1]>1_000_000{return -1}}
		mut loads:=[64]i64{};mut ids:=[64]i64{};mut bins:=0
		for i in 0..n{size:=input[i+1];mut b:=0;for b<bins&&loads[b]+size>1_000_000{b++};if b==bins{loads[bins]=size;bins++}else{loads[b]+=size};ids[i]=i64(b)}
		required:=(n+1)*8;if capacity<usize(required)||unsafe{output==nil}{return -2}
		put_i64_le(mut output,0,i64(bins));for i in 0..n{put_i64_le(mut output,8*(i+1),ids[i])};return i64(required)
	}
}
