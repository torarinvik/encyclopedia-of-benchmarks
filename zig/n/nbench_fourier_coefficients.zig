const std=@import("std");
const MAX_N:usize=16;
const INVALID_RESULT:f64=-1.0e300;
fn term(x:f64,omega:f64,select:usize)f64{const base=std.math.pow(f64,x+1.0,x);if(select==0)return base;if(select==1)return base*std.math.cos(omega*x);return base*std.math.sin(omega*x);}
fn integrate(omega:f64,select:usize)f64{var x:f64=0;const dx=(2.0-0.0)/200.0;var value=term(0,omega,select)/2.0;var steps:usize=200;if(steps!=1){steps-=1;while(true){steps-=1;if(steps==0)break;x+=dx;value+=term(x,omega,select);}}return(value+term(2.0,omega,select)/2.0)*dx;}
export fn nbench_fourier_coefficients(input:?[*]const i64,length:usize)f64{
 const values=input orelse return INVALID_RESULT;if(length<1 or length>2)return INVALID_RESULT;const raw=values[0];if(raw<1 or raw>MAX_N or length!=1)return INVALID_RESULT;const n:usize=@intCast(raw);var a=[_]f64{0}**MAX_N;var b=[_]f64{0}**MAX_N;a[0]=integrate(0,0)/2.0;
 for(1..n)|i|{const omega=3.1415926535897932*@as(f64,@floatFromInt(i));a[i]=integrate(omega,1);b[i]=integrate(omega,2);}
 var checksum:f64=0;for(0..n)|i|checksum+=@as(f64,@floatFromInt(i+1))*a[i];for(1..n)|i|checksum+=@as(f64,@floatFromInt(i))*b[i];if(!std.math.isFinite(checksum))return INVALID_RESULT;return checksum;
}
