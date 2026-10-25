module cbench_rsynth_f0_flutter

import math

@[export: 'cbench_rsynth_f0_flutter']
pub fn cbench_rsynth_f0_flutter(input &i64,n usize)i64{
	unsafe{
		if input==nil||n==0||n>4{return -1}
		if n!=3||input[0]<0||input[0]>20000||input[1]<0||input[1]>100||input[2]<0||input[2]>1_000_000{return -1}
		f0:=input[0];flutter:=input[1];t:=input[2];original:=f0/10;pi:=3.1415927
		fla:=f64(flutter)/50.0;flb:=f64(original)/100.0
		flc:=math.sin(2.0*pi*12.7*f64(t));fld:=math.sin(2.0*pi*7.1*f64(t));fle:=math.sin(2.0*pi*4.7*f64(t))
		delta:=fla*flb*(flc+fld+fle)*10.0
		return f0+i64(delta)
	}
}
