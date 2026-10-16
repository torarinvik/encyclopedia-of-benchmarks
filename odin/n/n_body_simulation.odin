package n_body_simulation
import "core:c"
import "core:math"
put_double :: proc(outp:[^]u8,off:int,x:f64){bits:=transmute(u64)x;for k:=0;k<8;k+=1{outp[off+k]=u8(bits>>u64(8*k))}}
@(export)
n_body_simulation :: proc "c"(v:[^]i64,n:c.size_t,outp:[^]u8,cap:c.size_t)->i64{
 if v==nil||n<6 do return -1;nb,steps,dtm,gm,tf,sm:=v[0],v[1],v[2],v[3],v[4],v[5];if nb<2||nb>4||steps<0||steps>4||dtm<1||dtm>1000||gm<0||gm>1000||tf<1||tf>10||sm<1||sm>3000||n!=c.size_t(6+5*nb)do return -1
 count:=int(nb);x,y,vx,vy,mass:[4]f64
 for i:=0;i<count;i+=1{a,b,cx,dy,m:=v[6+5*i],v[7+5*i],v[8+5*i],v[9+5*i],v[10+5*i];if a < -1000||a>1000||b < -1000||b>1000||cx < -100||cx>100||dy < -100||dy>100||m<1||m>1000 do return -1;x[i],y[i],vx[i],vy[i],mass[i]=f64(a),f64(b),f64(cx),f64(dy),f64(m)}
 dt: f64=(f64(dtm)/1000.0)*f64(tf);g:=f64(gm)/1000.0;soft:=f64(sm)/1000.0
 for step:=i64(0);step<steps;step+=1{for i:=0;i<count;i+=1{fx,fy:f64=0,0;for j:=0;j<count;j+=1{if i!=j{dx,dy:=x[j]-x[i],y[j]-y[i];dist:=math.sqrt(dx*dx+dy*dy+soft);cube:=dist*dist*dist;fx+=g*mass[j]*dx/cube;fy+=g*mass[j]*dy/cube}};vx[i]+=fx*dt;vy[i]+=fy*dt};for i:=0;i<count;i+=1{x[i]+=vx[i]*dt;y[i]+=vy[i]*dt}}
 bytes:=count*32;if outp==nil||cap<c.size_t(bytes)do return -2;for i:=0;i<count;i+=1{put_double(outp,4*i*8,x[i]);put_double(outp,(4*i+1)*8,y[i]);put_double(outp,(4*i+2)*8,vx[i]);put_double(outp,(4*i+3)*8,vy[i])};return i64(bytes)
}
