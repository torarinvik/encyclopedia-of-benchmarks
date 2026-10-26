module deterministic_line_search
fn put_i64_le(mut out &u8,p int,x i64){mut u:=u64(x);for b in 0..8{unsafe{out[p+b]=u8(u&255)};u>>=8}}
@[export:'deterministic_line_search']
pub fn deterministic_line_search(input &i64,length usize,mut output &u8,capacity usize)i64{
	if unsafe{input==nil}||length!=1{return -1}
	unsafe{
		target:=input[0];if target==0||target< -50000||target>50000{return -1}
		distance:=if target<0 {-target} else {target};mut traveled:=i64(0);mut leg:=i64(0);mut depth:=i64(1)
		for{negative:=leg%2==0;if(target<0)==negative&&distance<=depth{traveled+=distance;break};traveled+=2*depth;depth*=2;leg++}
		if capacity<16||unsafe{output==nil}{return -2};put_i64_le(mut output,0,traveled);put_i64_le(mut output,8,leg);return 16
	}
}
