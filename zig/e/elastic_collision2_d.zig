const std=@import("std");
export fn elastic_collision2_d(v:[*]const i64,n:usize)i64{
 if(n!=12)return -1
 for([_]usize{0,1,6,7})|i|{if(v[i]<-200000 or v[i]>200000)return -1;}
 for([_]usize{2,3,8,9})|i|{if(v[i]<-5000 or v[i]>5000)return -1;}
 if(v[4]<1000 or v[4]>100000 or v[10]<1000 or v[10]>100000 or v[5]<1 or v[5]>10000 or v[11]<1 or v[11]>10000)return -1;
 const dx=@as(f64,@floatFromInt(v[6]-v[0]));const dy=@as(f64,@floatFromInt(v[7]-v[1]));const dist=@sqrt(dx*dx+dy*dy);if(dist==0)return -1;
 var ox=@as(f64,@floatFromInt(v[2]));var oy=@as(f64,@floatFromInt(v[3]));
 if(!(dist<@as(f64,@floatFromInt(v[5]+v[11])))){const nx=dx/dist;const ny=dy/dist;const rv=@as(f64,@floatFromInt(v[8]-v[2]))*nx+@as(f64,@floatFromInt(v[9]-v[3]))*ny;if(rv<=0){const m1=@as(f64,@floatFromInt(v[4]));const m2=@as(f64,@floatFromInt(v[10]));const j=-2.0*rv/(1.0/m1+1.0/m2);ox-=j*nx/m1;oy-=j*ny/m1;}}
 const qx:i64=@intFromFloat(@floor(ox+0.5));const qy:i64=@intFromFloat(@floor(oy+0.5));if(qx< -32768 or qx>32767 or qy< -32768 or qy>32767)return -1;
 return ((qx&0xffff)<<16)|(qy&0xffff);
}
