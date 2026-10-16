proc rnd(x:float64):int64=
 let z=x*1000.0
 if z>=0:return int64(z+0.5)
 -int64(-z+0.5)
proc liang_barsky*(v:ptr UncheckedArray[int64],n:csize_t):int64 {.cdecl,exportc:"liang_barsky".}=
 if n!=8:return -1
 for i in 0..<8:
  if v[i]<-5 or v[i]>5:return -1
 let xmin=float64(v[0]);let ymin=float64(v[1]);let xmax=float64(v[2]);let ymax=float64(v[3]);let x0=float64(v[4]);let y0=float64(v[5]);let x1=float64(v[6]);let y1=float64(v[7])
 if xmin>=xmax or ymin>=ymax:return -1
 let dx=x1-x0;let dy=y1-y0
 let p=[-dx,dx,-dy,dy];let q=[x0-xmin,xmax-x0,y0-ymin,ymax-y0]
 var t0=0.0;var t1=1.0
 for i in 0..<4:
  let t=q[i]/p[i]
  if p[i]==0 and q[i]<0:return -1
  elif p[i]<0:
   if t>t1:return -1
   if t>t0:t0=t
  elif p[i]>0:
   if t<t0:return -1
   if t<t1:t1=t
 let z=[x0+t0*dx,y0+t0*dy,x0+t1*dx,y0+t1*dy]
 var r:int64=0
 for x in z:r=r*10001+rnd(x)+5000
 r
