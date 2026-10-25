module cbench_rsynth_impulsive_glottal

import math

@[export: 'cbench_rsynth_impulsive_glottal_sample']
pub fn cbench_rsynth_impulsive_glottal_sample(input &f64,n usize,mut output &f64,cap usize)i64{
	unsafe{
		if input==nil||n==0||n>3{return -1}
		for i in 0..n{if !input[i].is_finite(){return -1}}
		if n!=2||input[0]<40||input[0]>263||input[0]!=f64(int(input[0]))||input[1]<0||input[1]>299||input[1]!=f64(int(input[1])){return -1}
		open:=int(input[0]);target:=int(input[1]);rate:=8000
		minus_pi:=f32(-math.pi/f64(rate));two_pi:=f32(-2.0*f64(minus_pi));bw:=rate/open
		r:=f32(math.exp(f64(minus_pi)*f64(bw)));c:=f32(-(r*r));b:=f32(f64(r)*math.cos(f64(two_pi)*0.0)*2.0)
		mut a:=f32(1.0-f64(b)-f64(c));t:=f32(f64(open)*0.00833);a=f32(a*(t*t))
		mut p1:=f32(0);mut p2:=f32(0);mut result:=f32(0)
		for i in 0..(target+1){impulse:=f32(if i==1{13_000_000.0}else if i==2{-13_000_000.0}else{0.0});mut x:=f32(a*impulse);x=f32(x+f32(b*p1));x=f32(x+f32(c*p2));p2=p1;p1=x;result=x}
		if output==nil||cap<1{return -2};output[0]=f64(result);return 1
	}
}
