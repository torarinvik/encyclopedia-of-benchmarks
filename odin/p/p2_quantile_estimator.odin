package p2_quantile_estimator

import "core:c"

@(export)
p2_quantile_estimator :: proc "c" (v: [^]i64, n: c.size_t) -> f64 {
 if v==nil||n<2||n>65||v[0]<1||v[0]>64||n!=c.size_t(v[0]+1) do return -1e300
 count:=int(v[0]);q:[5]f64;pos,desired:[5]f64;inc:=[5]f64{0,0.25,0.5,0.75,1};seen:=0
 for z:=0;z<count;z+=1{if v[z+1]<-2_147_483_648||v[z+1]>2_147_483_647 do return -1e300;x:=f64(v[z+1]);if seen<5{q[seen]=x;seen+=1;if seen==5{for a:=1;a<5;a+=1{temp:=q[a];b:=a;for b>0&&q[b-1]>temp{q[b]=q[b-1];b-=1};q[b]=temp};for i:=0;i<5;i+=1{pos[i]=f64(i+1);desired[i]=f64(i+1)}};continue};k:=3;if x<q[0]{q[0]=x;k=0}else{for i:=1;i<4;i+=1{if x<q[i]{k=i-1;break}};if x>q[4]{q[4]=x}};for i:=k+1;i<5;i+=1{pos[i]+=1};for i:=0;i<5;i+=1{desired[i]+=inc[i]};for i:=1;i<4;i+=1{drift:=desired[i]-pos[i];sr:=drift>=1&&pos[i+1]-pos[i]>1;sl:=drift<=-1&&pos[i-1]-pos[i]<-1;if !sr&&!sl{continue};dir:=f64(-1);if sr{dir=1};left:=pos[i]-pos[i-1];right:=pos[i+1]-pos[i];cand:=q[i]+dir/(left+right)*((left+dir)*(q[i+1]-q[i])/right+(right-dir)*(q[i]-q[i-1])/left);if q[i-1]<cand&&cand<q[i+1]{q[i]=cand}else{nb:=i+int(dir);q[i]+=dir*(q[nb]-q[i])/(pos[nb]-pos[i])};pos[i]+=dir}}
 if seen<5{for a:=1;a<count;a+=1{temp:=q[a];b:=a;for b>0&&q[b-1]>temp{q[b]=q[b-1];b-=1};q[b]=temp};rank:=0.5*f64(count-1);lo:=int(rank);hi:=lo+1;if hi>=count{hi=lo};return q[lo]+(rank-f64(lo))*(q[hi]-q[lo])};return q[2]
}
