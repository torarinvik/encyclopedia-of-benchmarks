module elastic_collision2_d
import math
@[export: 'elastic_collision2_d']
pub fn elastic_collision2_d(v &i64,n usize)i64{
 if isnil(v)||n!=12{return -1}
 for i in [0,1,6,7]{if v[i]< -200000||v[i]>200000{return -1}}
 for i in [2,3,8,9]{if v[i]< -5000||v[i]>5000{return -1}}
 if v[4]<1000||v[4]>100000||v[10]<1000||v[10]>100000||v[5]<1||v[5]>10000||v[11]<1||v[11]>10000{return -1}
 dx:=f64(v[6]-v[0]);dy:=f64(v[7]-v[1]);dist:=math.sqrt(dx*dx+dy*dy);if dist==0{return -1}
 mut ox:=f64(v[2]);mut oy:=f64(v[3])
 if !(dist<f64(v[5]+v[11])){nx:=dx/dist;ny:=dy/dist;rv:=f64(v[8]-v[2])*nx+f64(v[9]-v[3])*ny;if rv<=0{j:=-2.0*rv/(1.0/f64(v[4])+1.0/f64(v[10]));ox-=j*nx/f64(v[4]);oy-=j*ny/f64(v[4])}}
 qx:=i64(math.floor(ox+0.5));qy:=i64(math.floor(oy+0.5));if qx< -32768||qx>32767||qy< -32768||qy>32767{return -1}
 return ((qx&0xffff)<<16)|(qy&0xffff)
}
