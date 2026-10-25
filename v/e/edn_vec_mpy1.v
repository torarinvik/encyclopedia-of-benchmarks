module edn_vec_mpy1
fn put64(mut out &u8,pos usize,value i64){u:=u64(value);for j in 0..8{unsafe{out[pos+j]=u8(u>>(8*j))}}}
@[export:'edn_vec_mpy1']
pub fn edn_vec_mpy1(values &i64,length usize,mut output &u8,capacity usize)i64{unsafe{if values==nil||length<4||length>130{return -1};count:=values[0];if count<1||count>64||length!=usize(2+2*count){return -1};q:=int(count);scale:=values[length-1];if scale< -1024||scale>1023{return -1};mut y:=[64]i64{};mut x:=[64]i64{};for i in 0..q{y[i]=values[1+i];x[i]=values[1+q+i];if y[i]< -1024||y[i]>1023||x[i]< -1024||x[i]>1023{return -1}};bytes:=8*q;if output==nil||capacity<bytes{return -2};for i in 0..q{y[i]+=(scale*x[i])>>15};for i in 0..q{put64(output,8*i,y[i])};return i64(bytes)}}
