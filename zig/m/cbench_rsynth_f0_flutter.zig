const std=@import("std");
export fn cbench_rsynth_f0_flutter(input:[*c]const i64,n:usize) i64{
 if(input==null or n==0 or n>4)return -1;if(n!=3 or input[0]<0 or input[0]>20000 or input[1]<0 or input[1]>100 or input[2]<0 or input[2]>1_000_000)return -1;
 const f0=input[0];const flutter=input[1];const t=input[2];const original=f0/10;const pi:f64=3.1415927;
 const fla=@as(f64,@floatFromInt(flutter))/50.0;const flb=@as(f64,@floatFromInt(original))/100.0;
 const flc=@sin(2.0*pi*12.7*@as(f64,@floatFromInt(t)));const fld=@sin(2.0*pi*7.1*@as(f64,@floatFromInt(t)));const fle=@sin(2.0*pi*4.7*@as(f64,@floatFromInt(t)));
 const delta=fla*flb*(flc+fld+fle)*10.0;return f0+@as(i64,@intFromFloat(delta));
}
