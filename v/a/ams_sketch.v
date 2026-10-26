module ams_sketch
fn put_i64_le(mut out &u8,x i64){mut u:=u64(x);for b in 0..8{unsafe{out[b]=u8(u&255)};u>>=8}}
@[export:'ams_sketch']
pub fn ams_sketch(input &i64,length usize,mut output &u8,capacity usize)i64{
	if unsafe{input==nil}||length<4||length>116{return -1}
	unsafe{
		d0,w0,k0,u0:=input[0],input[1],input[2],input[3]
		if(d0!=1&&d0!=3&&d0!=5)||w0<1||w0>8||k0<1||k0>8||u0<0||u0>16{return -1}
		d,w,k,u:=int(d0),int(w0),int(k0),int(u0);start:=4+2*d*k;if length!=usize(start+2*u){return -1}
		for r in 0..d{for key in 0..k{p:=4+2*(r*k+key);if input[p]<0||input[p]>=w0||(input[p+1]!=-1&&input[p+1]!=1){return -1}}}
		for i in 0..u{key,weight:=input[start+2*i],input[start+2*i+1];if key<0||key>=k0||weight< -1000||weight>1000{return -1}}
		mut counters:=[5][8]i64{};mut estimates:=[5]i64{}
		for i in 0..u{key:=int(input[start+2*i]);weight:=input[start+2*i+1];for r in 0..d{p:=4+2*(r*k+key);b:=int(input[p]);counters[r][b]+=weight*input[p+1]}}
		for r in 0..d{for b in 0..w{estimates[r]+=counters[r][b]*counters[r][b]}}
		for i in 1..d{x:=estimates[i];mut j:=i;for j>0&&estimates[j-1]>x{estimates[j]=estimates[j-1];j--};estimates[j]=x}
		if capacity<8||unsafe{output==nil}{return -2};put_i64_le(mut output,estimates[d/2]);return 8
	}
}
