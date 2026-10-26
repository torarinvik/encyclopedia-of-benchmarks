// Clean-room TSVC s471 profile; see package rights note.
const max_n=32
const max_input_length=130
fn put64(out &u8,pos int,value i64){mut bits:=u64(value);for j in 0..8{unsafe{out[pos+j]=u8(bits&255)};bits>>=8}}
@[export:'tsvc_s471_ordered_two_vector_map']
pub fn tsvc_s471_ordered_two_vector_map(input &i64,input_length usize,output &u8,capacity usize)i64{
 if unsafe{input==nil}||input_length<6||input_length>max_input_length{return -1}
 rn:=unsafe{input[0]};rp:=unsafe{input[1]};if rn<1||rn>max_n||rp<1||rp>4||input_length!=usize(2+4*rn){return -1}
 n:=int(rn);passes:=int(rp);mut x:=[max_n]f64{};mut b:=[max_n]f64{};mut c:=[max_n]f64{};mut d:=[max_n]f64{};mut e:=[max_n]f64{}
 for i in 0..n{bv:=unsafe{input[2+i]};cv:=unsafe{input[2+n+i]};dv:=unsafe{input[2+2*n+i]};ev:=unsafe{input[2+3*n+i]};if bv< -2||bv>2||cv< -2||cv>2||dv< -2||dv>2||ev< -2||ev>2{return -1};b[i]=f64(bv);c[i]=f64(cv);d[i]=f64(dv);e[i]=f64(ev)}
 bytes:=16*n;if unsafe{output==nil}||capacity<usize(bytes){return -2}
 for _ in 0..passes{for i in 0..n{x[i]=b[i]+d[i]*d[i];b[i]=c[i]+d[i]*e[i]}}
 for i in 0..n{put64(output,8*i,i64(x[i]));put64(output,8*(n+i),i64(b[i]))};return i64(bytes)
}
