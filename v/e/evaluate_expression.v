module main
import math
fn put32(out &u8, x u32) { for k in 0..4 { unsafe { out[k]=u8((x>>(8*k))&255) } } }
fn put_f64(out &u8, x f64) { mut bits:=math.bits_from_f64(x); for k in 0..8 { unsafe { out[4+k]=u8(bits&255) }; bits>>=8 } }
@[export: 'evaluate_expression']
pub fn evaluate_expression(v &i64,n usize,out &u8,cap usize)i64 {
 if isnil(v)||n<3||n>131{return -1}; count:=unsafe{v[0]}; if count<1||count>64||n!=usize(1+2*count){return -1}
 mut stack:=[]f64{len:64}; mut depth:=0; mut valid:=true
 for i in 0..count { op:=unsafe{v[1+2*i]}; x:=unsafe{v[2+2*i]}; if op==0 { if x < -1000000000||x>1000000000{return -1}; stack[depth]=f64(x)/1000;depth++ } else if op>=1&&op<=4 { if x!=0{return -1}; if depth<2{valid=false;break};depth--;r:=stack[depth];depth--;l:=stack[depth];if op==1{stack[depth]=l+r}else if op==2{stack[depth]=l-r}else if op==3{stack[depth]=l*r}else if r==0{valid=false;break}else{stack[depth]=l/r};depth++ } else { valid=false;break } }
 valid=valid&&depth==1; needed:=usize(4);if valid{needed=12};if isnil(out)||cap<needed{return -2};put32(out,u32(if valid{1}else{0}));if valid{put_f64(out,stack[0])};return i64(needed)
}
