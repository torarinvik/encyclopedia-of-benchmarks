package liang_barsky
import "core:c"
rnd :: proc(x:f64)->i64{z:=x*1000.0;if z>=0{return i64(z+0.5)};return -i64(-z+0.5)}
@(export) liang_barsky :: proc "c"(v:[^]i64,n:c.size_t)->i64{if n!=8{return -1};for i:c.size_t=0;i<8;i+=1{if v[i]<-5||v[i]>5{return -1}};xmin,ymin,xmax,ymax,x0,y0,x1,y1:=f64(v[0]),f64(v[1]),f64(v[2]),f64(v[3]),f64(v[4]),f64(v[5]),f64(v[6]),f64(v[7]);if xmin>=xmax||ymin>=ymax{return -1};dx,dy:=x1-x0,y1-y0;p:=[4]f64{-dx,dx,-dy,dy};q:=[4]f64{x0-xmin,xmax-x0,y0-ymin,ymax-y0};t0,t1:f64=0,1;for i:=0;i<4;i+=1{t:=q[i]/p[i];if p[i]==0&&q[i]<0{return -1}else if p[i]<0{if t>t1{return -1};if t>t0{t0=t}}else if p[i]>0{if t<t0{return -1};if t<t1{t1=t}}};z:=[4]f64{x0+t0*dx,y0+t0*dy,x0+t1*dx,y0+t1*dy};r:i64=0;for x in z{r=r*10001+rnd(x)+5000};return r}
