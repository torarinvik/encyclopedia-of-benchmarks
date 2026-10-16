fn put_i32(mut outp &u8,off int,x i64){mut bits:=u32(i32(x));for k in 0..4{unsafe{outp[off+k]=u8(bits&255)};bits>>=8}}
@[export:'operators']
pub fn operators(v &i64,n usize,outp &u8,cap usize)i64{
 if n<5{return -1};op:=unsafe{v[0]};ra:=unsafe{v[1]};ca:=unsafe{v[2]};if(op!=0&&op!=1)||ra<1||ra>16||ca<0||ca>16||ra*ca>256{return -1};count:=int(ra*ca);pb:=3+count;if n<pb+2{return -1};rb:=unsafe{v[pb]};cb:=unsafe{v[pb+1]};if rb<1||rb>16||cb<0||cb>16||rb*cb>256||n!=usize(pb+2+rb*cb){return -1}
 for i in 0..count{x:=unsafe{v[3+i]};if x < -1000000||x>1000000{return -1}};for i in 0..int(rb*cb){x:=unsafe{v[pb+2+i]};if x < -1000000||x>1000000{return -1}};if ra!=rb||ca!=cb{return -1};bytes:=count*4;if cap<bytes||(bytes>0&&isnil(outp)){return -2};for i in 0..count{a:=unsafe{v[3+i]};b:=unsafe{v[pb+2+i]};put_i32(mut outp,i*4,if op==0{a+b}else{a-b})};return i64(count)
}
