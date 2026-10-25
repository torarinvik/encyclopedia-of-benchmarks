const std=@import("std");
fn f32r(x:f64) f32{return @floatCast(x);}
export fn cbench_rsynth_impulsive_glottal_sample(input:[*c]const f64,n:usize,output:[*c]f64,cap:usize) i64{
 if(input==null or n==0 or n>3)return -1;for(0..n)|i|{if(!std.math.isFinite(input[i]))return -1;}
 if(n!=2 or input[0]<40 or input[0]>263 or @trunc(input[0])!=input[0] or input[1]<0 or input[1]>299 or @trunc(input[1])!=input[1])return -1;
 const open:i64=@intFromFloat(input[0]);const target:i64=@intFromFloat(input[1]);const rate:i64=8000;
 const minus_pi:f32=f32r(-std.math.pi/@as(f64,@floatFromInt(rate)));const two_pi:f32=f32r(-2.0*@as(f64,minus_pi));const bw=rate/open;
 const r:f32=f32r(@exp(@as(f64,minus_pi)*@as(f64,@floatFromInt(bw))));const c=-(r*r);const b:f32=f32r(@as(f64,r)*@cos(@as(f64,two_pi)*0.0)*2.0);
 var a:f32=f32r(1.0-@as(f64,b)-@as(f64,c));const t:f32=f32r(@as(f64,@floatFromInt(open))*0.00833);a=f32r(@as(f64,a)*@as(f64,t*t));
 var p1:f32=0;var p2:f32=0;var result:f32=0;var i:i64=0;while(i<=target):(i+=1){const impulse:f32=if(i==1) 13_000_000.0 else if(i==2) -13_000_000.0 else 0.0;var x=f32r(@as(f64,a*impulse));x=f32r(@as(f64,x)+@as(f64,b*p1));x=f32r(@as(f64,x)+@as(f64,c*p2));p2=p1;p1=x;result=x;}
 if(output==null or cap<1)return -2;output[0]=result;return 1;
}
