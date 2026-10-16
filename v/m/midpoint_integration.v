import math
fn store_i64_le(mut out &u8,x i64){u:=u64(x);for b in 0..8{unsafe{out[b]=u8((u>>(8*b))&255)}}}
@[export:'midpoint_integration']
pub fn midpoint_integration(input &i64,length usize,mut output &u8,capacity usize)i64{if unsafe{input==nil}||length!=4{return -1};unsafe{f:=input[0];steps:=input[1];aa:=input[2];bb:=input[3];if f<0||f>2||steps<1||steps>256||aa< -1_000_000||aa>1_000_000||bb<aa||bb>1_000_000{return -1};if output==nil||capacity<8{return -2};a:=f64(aa)/1e6;b:=f64(bb)/1e6;h:=(b-a)/f64(steps);mut sum:=f64(0);for i in 0..int(steps){x:=a+f64(i)*h+h/2;y:=if f==0{1.0}else if f==1{x}else{x*x};sum+=y};store_i64_le(mut output,i64(math.floor(h*sum*1e9+0.5)));return 8}}
