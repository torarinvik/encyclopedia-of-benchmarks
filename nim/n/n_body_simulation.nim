import std/math
proc putDouble(outp:ptr UncheckedArray[uint8],offset:int,x:float64)=
 let bits=cast[uint64](x)
 for k in 0..<8:outp[offset+k]=uint8((bits shr (8*k)) and 255)
proc n_body_simulation*(v:ptr UncheckedArray[int64],n:csize_t,outp:ptr UncheckedArray[uint8],cap:csize_t):int64 {.cdecl,exportc:"n_body_simulation".}=
 if v==nil or n<6:return -1
 let nb=v[0];let steps=v[1];let dtm=v[2];let gm=v[3];let tf=v[4];let sm=v[5]
 if nb<2 or nb>4 or steps<0 or steps>4 or dtm<1 or dtm>1000 or gm<0 or gm>1000 or tf<1 or tf>10 or sm<1 or sm>3000 or n!=csize_t(6+5*nb):return -1
 let count=int(nb);var x,y,vx,vy,mass:array[4,float64]
 for i in 0..<count:
  let a=v[6+5*i];let b=v[7+5*i];let c=v[8+5*i];let d=v[9+5*i];let m=v[10+5*i]
  if a < -1000 or a>1000 or b < -1000 or b>1000 or c < -100 or c>100 or d < -100 or d>100 or m<1 or m>1000:return -1
  x[i]=float64(a);y[i]=float64(b);vx[i]=float64(c);vy[i]=float64(d);mass[i]=float64(m)
 let dt=(float64(dtm)/1000.0)*float64(tf);let g=float64(gm)/1000.0;let soft=float64(sm)/1000.0
 for step in 0..<int(steps):
  for i in 0..<count:
   var fx=0.0;var fy=0.0
   for j in 0..<count:
    if i!=j:
     let dx=x[j]-x[i];let dy=y[j]-y[i];let distance=sqrt(dx*dx+dy*dy+soft);let cube=distance*distance*distance
     fx+=g*mass[j]*dx/cube;fy+=g*mass[j]*dy/cube
   vx[i]+=fx*dt;vy[i]+=fy*dt
  for i in 0..<count:x[i]+=vx[i]*dt;y[i]+=vy[i]*dt
 let bytes=count*32
 if outp==nil or cap<csize_t(bytes):return -2
 for i in 0..<count:putDouble(outp,4*i*8,x[i]);putDouble(outp,(4*i+1)*8,y[i]);putDouble(outp,(4*i+2)*8,vx[i]);putDouble(outp,(4*i+3)*8,vy[i])
 int64(bytes)
