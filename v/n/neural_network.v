import math
fn putd(mut o &u8,p int,x f64){bits:=u64(math.bits_from_f64(x));for k in 0..8{unsafe{o[p+k]=u8(bits&255)};bits>>=8}}
fn sig(x f64)f64{1.0/(1.0+math.exp(-x))}
@[export:'neural_network']
pub fn neural_network(v &i64,n usize,o &u8,cap usize)i64{if isnil(v)||n<7{return -1};ni:=unsafe{v[0]};nh:=unsafe{v[1]};no:=unsafe{v[2]};if ni<1||ni>3||nh<1||nh>3||no<1||no>3||n!=usize(3+ni+ni*nh+nh*no){return -1};for i in 3..int(n){x:=unsafe{v[i]};if x < -1000||x>1000{return -1}};if isnil(o)||cap<int(no)*8{return -2};xs:=3;w1:=xs+int(ni);w2:=w1+int(ni*nh);mut h:=[3]f64{};for j in 0..int(nh){mut z:=0.0;for i in 0..int(ni){z+=f64(unsafe{v[xs+i]})/1000.0*(f64(unsafe{v[w1+i*int(nh)+j]})/1000.0)};h[j]=sig(z)};for j in 0..int(no){mut z:=0.0;for i in 0..int(nh){z+=h[i]*(f64(unsafe{v[w2+i*int(no)+j]})/1000.0)};putd(mut o,j*8,sig(z))};no*8}
