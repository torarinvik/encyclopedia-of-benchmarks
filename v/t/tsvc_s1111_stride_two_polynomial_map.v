// Clean-room TSVC s1111 profile; see package rights note.
const max_n=32
fn put64(out &u8,pos int,value i64){mut bits:=u64(value);for j in 0..8{unsafe{out[pos+j]=u8(bits&255)};bits>>=8}}
@[export:'tsvc_s1111_stride_two_polynomial_map']
pub fn tsvc_s1111_stride_two_polynomial_map(input &i64,length usize,output &u8,capacity usize)i64{
 if unsafe{input==nil}||length<6||length>161{return -1};nr:=unsafe{input[0]};if nr<1||nr>max_n{return -1};n:=int(nr);if int(length)!=1+5*n{return -1}
 mut a:=[64]i64{};mut b:=[32]i64{};mut c:=[32]i64{};mut d:=[32]i64{};mut off:=1
 for i in 0..2*n{x:=unsafe{input[off+i]};if x< -2||x>2{return -1};a[i]=x};off+=2*n
 for i in 0..n{x:=unsafe{input[off+i]};if x< -2||x>2{return -1};b[i]=x};off+=n
 for i in 0..n{x:=unsafe{input[off+i]};if x< -2||x>2{return -1};c[i]=x};off+=n
 for i in 0..n{x:=unsafe{input[off+i]};if x< -2||x>2{return -1};d[i]=x}
 bytes:=16*n;if unsafe{output==nil}||capacity<usize(bytes){return -2};for i in 0..n{a[2*i]=c[i]*b[i]+d[i]*b[i]+c[i]*c[i]+d[i]*b[i]+d[i]*c[i]};for i in 0..2*n{put64(output,8*i,a[i])};return i64(2*n)
}
