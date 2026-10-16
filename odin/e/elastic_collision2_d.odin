package elastic_collision2_d
import "core:math"
@(export)
elastic_collision2_d :: proc "c" (v: [^]i64, n: u64) -> i64 {
 if v == nil || n != 12 do return -1
 for i := 0; i < 12; i += 1 {
  if i == 0 || i == 1 || i == 6 || i == 7 { if v[i] < -200000 || v[i] > 200000 do return -1 }
  if i == 2 || i == 3 || i == 8 || i == 9 { if v[i] < -5000 || v[i] > 5000 do return -1 }
 }
 if v[4]<1000||v[4]>100000||v[10]<1000||v[10]>100000||v[5]<1||v[5]>10000||v[11]<1||v[11]>10000 do return -1
 dx:=f64(v[6]-v[0]);dy:=f64(v[7]-v[1]);dist:=math.sqrt(dx*dx+dy*dy);if dist==0 do return -1
 ox,oy:=f64(v[2]),f64(v[3])
 if !(dist<f64(v[5]+v[11])) { nx,ny:=dx/dist,dy/dist;rv:=f64(v[8]-v[2])*nx+f64(v[9]-v[3])*ny;if rv<=0 { j:=-2.0*rv/(1.0/f64(v[4])+1.0/f64(v[10]));ox-=j*nx/f64(v[4]);oy-=j*ny/f64(v[4]) } }
 qx,qy:=i64(math.floor(ox+0.5)),i64(math.floor(oy+0.5));if qx< -32768||qx>32767||qy< -32768||qy>32767 do return -1
 return ((qx&0xffff)<<16)|(qy&0xffff)
}
