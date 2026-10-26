// Clean-room TSVC s232 profile; see package rights note.
fn put64(out &u8,p int,v i64){mut b:=u64(v);for j in 0..8{unsafe{out[p+j]=u8(b&255)};b>>=8}}
@[export:'tsvc_s232_triangular_row_square_recurrence']
pub fn tsvc_s232_triangular_row_square_recurrence(input &i64,length usize,output &u8,capacity usize)i64{if unsafe{input==nil}||length<9||length>51{return -1};nr:=unsafe{input[0]};if nr<2||nr>5{return -1};n:=int(nr);nn:=n*n;if int(length)!=1+2*nn{return -1};mut a:=[25]i64{};mut b:=[25]i64{};for i in 0..nn{x:=unsafe{input[1+i]};y:=unsafe{input[1+nn+i]};if x< -1||x>1||y< -1||y>1{return -1};a[i]=x;b[i]=y};if unsafe{output==nil}||capacity<usize(8*nn){return -2};for j in 1..n{for i in 1..j+1{x:=a[j*n+i-1];a[j*n+i]=x*x+b[j*n+i]}};for i in 0..nn{put64(output,8*i,a[i])};return i64(nn)}
