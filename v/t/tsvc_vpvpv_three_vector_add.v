// Clean-room implementation of TSVC vpvpv; see package rights note.
const max_n=32
const max_input_length=98
fn store_i64_le(out &u8,pos int,value i64){mut bits:=u64(value);for j in 0..8{unsafe{out[pos+j]=u8(bits&255)};bits>>=8}}
@[export:'tsvc_vpvpv_three_vector_add']
pub fn tsvc_vpvpv_three_vector_add(input &i64,input_length usize,output &u8,capacity usize)i64{
 if unsafe{input==nil}||input_length<5||input_length>max_input_length{return -1}
 rn:=unsafe{input[0]};rp:=unsafe{input[1]};if rn<1||rn>max_n||rp<1||rp>4||input_length!=usize(2+3*rn){return -1}
 n:=int(rn);passes:=int(rp);mut a:=[max_n]f64{};mut b:=[max_n]f64{};mut c:=[max_n]f64{}
 for i in 0..n{av:=unsafe{input[2+i]};bv:=unsafe{input[2+n+i]};cv:=unsafe{input[2+2*n+i]};if av< -2||av>2||bv< -2||bv>2||cv< -2||cv>2{return -1};a[i]=f64(av);b[i]=f64(bv);c[i]=f64(cv)}
 bytes:=8*n;if unsafe{output==nil}||capacity<usize(bytes){return -2}
 for _ in 0..passes{for i in 0..n{a[i]+=b[i]+c[i]}}
 for i in 0..n{store_i64_le(output,8*i,i64(a[i]))};return i64(bytes)
}
