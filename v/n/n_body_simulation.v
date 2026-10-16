import math
fn put_double(mut outp &u8,off int,x f64){mut bits:=u64(math.bits_from_f64(x));for k in 0..8{unsafe{outp[off+k]=u8(bits&255)};bits>>=8}}
@[export:'n_body_simulation']
pub fn n_body_simulation(v &i64,n usize,outp &u8,cap usize)i64{
 if n<6{return -1};nb:=unsafe{v[0]};steps:=unsafe{v[1]};dtm:=unsafe{v[2]};gm:=unsafe{v[3]};tf:=unsafe{v[4]};sm:=unsafe{v[5]};if nb<2||nb>4||steps<0||steps>4||dtm<1||dtm>1000||gm<0||gm>1000||tf<1||tf>10||sm<1||sm>3000||n!=usize(6+5*nb){return -1};count:=int(nb)
 mut x:=[4]f64{};mut y:=[4]f64{};mut vx:=[4]f64{};mut vy:=[4]f64{};mut mass:=[4]f64{}
 for i in 0..count{a:=unsafe{v[6+5*i]};b:=unsafe{v[7+5*i]};c:=unsafe{v[8+5*i]};d:=unsafe{v[9+5*i]};m:=unsafe{v[10+5*i]};if a < -1000||a>1000||b < -1000||b>1000||c < -100||c>100||d < -100||d>100||m<1||m>1000{return -1};x[i]=f64(a);y[i]=f64(b);vx[i]=f64(c);vy[i]=f64(d);mass[i]=f64(m)}
 dt:=f64(dtm)/1000.0*f64(tf);g:=f64(gm)/1000.0;soft:=f64(sm)/1000.0
 for _ in 0..int(steps){for i in 0..count{mut fx:=f64(0);mut fy:=f64(0);for j in 0..count{if i!=j{dx:=x[j]-x[i];dy:=y[j]-y[i];dist:=math.sqrt(dx*dx+dy*dy+soft);cube:=dist*dist*dist;fx+=g*mass[j]*dx/cube;fy+=g*mass[j]*dy/cube}};vx[i]+=fx*dt;vy[i]+=fy*dt};for i in 0..count{x[i]+=vx[i]*dt;y[i]+=vy[i]*dt}}
 bytes:=count*32;if cap<bytes||isnil(outp){return -2};for i in 0..count{put_double(mut outp,4*i*8,x[i]);put_double(mut outp,(4*i+1)*8,y[i]);put_double(mut outp,(4*i+2)*8,vx[i]);put_double(mut outp,(4*i+3)*8,vy[i])};return i64(bytes)
}
