// Clean-room TSVC s113 profile; see package rights note.
fn put64(out &u8,p int,v i64){mut b:=u64(v);for j in 0..8{unsafe{out[p+j]=u8(b&255)};b>>=8}}
@[export:'tsvc_s113_invariant_anchor_add']
pub fn tsvc_s113_invariant_anchor_add(input &i64,length usize,output &u8,capacity usize)i64{if unsafe{input==nil}||length<3||length>129{return -1};nr:=unsafe{input[0]};if nr<1||nr>64{return -1};n:=int(nr);if int(length)!=1+2*n{return -1};mut a:=[64]i64{};mut b:=[64]i64{};for i in 0..n{x:=unsafe{input[1+i]};y:=unsafe{input[1+n+i]};if x< -2||x>2||y< -2||y>2{return -1};a[i]=x;b[i]=y};if unsafe{output==nil}||capacity<usize(8*n){return -2};anchor:=a[0];for i in 1..n{a[i]=anchor+b[i]};for i in 0..n{put64(output,8*i,a[i])};return i64(n)}
