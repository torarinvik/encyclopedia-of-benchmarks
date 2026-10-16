export fn pyramid(v: [*]const i64,n:usize) f64 {
 if(n!=3 or v[0]<0 or v[0]>1 or v[1]<1 or v[1]>10000000 or v[2]<1 or v[2]>10000000)return -1e300;
 const b=@as(f64,@floatFromInt(v[1]))/1000.0;const h=@as(f64,@floatFromInt(v[2]))/1000.0;const area=std.math.pow(f64,b,2.0);
 if(v[0]==0)return (area*h)/3.0;return area+((b*4.0)/2.0)*@sqrt(std.math.pow(f64,b/2.0,2.0)+std.math.pow(f64,h,2.0));
}
const std=@import("std");
