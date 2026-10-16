module p2_quantile_estimator

@[export: 'p2_quantile_estimator']
pub fn p2_quantile_estimator(v &i64, n usize) f64 {
 if isnil(v)||n<2||n>65||v[0]<1||v[0]>64||n!=usize(v[0])+1{return -1e300}
 count:=int(v[0]);mut q:=[5]f64{};mut pos:=[5]f64{};mut desired:=[5]f64{};inc:=[5]f64{0,.25,.5,.75,1};mut seen:=0
 for z in 0..count{if v[z+1]<-2147483648||v[z+1]>2147483647{return -1e300};x:=f64(v[z+1]);if seen<5{q[seen]=x;seen++;if seen==5{q.sort();for i in 0..5{pos[i]=f64(i+1);desired[i]=f64(i+1)}};continue};mut k:=3;if x<q[0]{q[0]=x;k=0}else{for i in 1..4{if x<q[i]{k=i-1;break}};if x>q[4]{q[4]=x}};for i in k+1..5{pos[i]+=1};for i in 0..5{desired[i]+=inc[i]};for i in 1..4{drift:=desired[i]-pos[i];sr:=drift>=1&&pos[i+1]-pos[i]>1;sl:=drift<=-1&&pos[i-1]-pos[i]<-1;if !sr&&!sl{continue};dir:=if sr{1.0}else{-1.0};left:=pos[i]-pos[i-1];right:=pos[i+1]-pos[i];candidate:=q[i]+dir/(left+right)*((left+dir)*(q[i+1]-q[i])/right+(right-dir)*(q[i]-q[i-1])/left);if q[i-1]<candidate&&candidate<q[i+1]{q[i]=candidate}else{nb:=i+int(dir);q[i]+=dir*(q[nb]-q[i])/(pos[nb]-pos[i])};pos[i]+=dir}}
 if seen<5{for a:=1;a<count;a++{x:=q[a];mut b:=a;for b>0&&q[b-1]>x{q[b]=q[b-1];b--};q[b]=x};rank:=.5*f64(count-1);lo:=int(rank);hi:=min(lo+1,count-1);return q[lo]+(rank-f64(lo))*(q[hi]-q[lo])};return q[2]
}
