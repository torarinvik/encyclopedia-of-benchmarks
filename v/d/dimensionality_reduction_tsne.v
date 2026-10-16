module dimensionality_reduction_tsne
import math
@[export: 'dimensionality_reduction_tsne']
pub fn dimensionality_reduction_tsne(v &f64,n usize,mut out &f64,cap usize)i64{
 unsafe{
  if v==nil||n!=5||v[0]!=1||v[1]!=3{return -1};for i in 2..5{if math.is_nan(v[i])||math.is_inf(v[i],0)||math.abs(v[i])>100{return -1}};if out==nil||cap<3{return -2}
  mut d:=[3][3]f64{};mut p:=[3][3]f64{};mut high:=[3][3]f64{};mut q:=[3][3]f64{};mut den:=[3][3]f64{}
  for i in 0..3{for j in 0..3{z:=v[2+i]-v[2+j];d[i][j]=z*z}}
  for i in 0..3{mut beta:=1.0;mut lo:=0.0;mut hi:=0.0;mut has_lo:=false;mut has_hi:=false;mut probs:=[3]f64{};for it in 0..50{mut e:=[3]f64{};mut total:=0.0;for j in 0..3{e[j]=if i==j{0.0}else{math.exp(-d[i][j]*beta)};total+=e[j]};if total==0{break};mut h:=0.0;for j in 0..3{probs[j]=e[j]/total;if probs[j]>0{h-=probs[j]*math.log2(probs[j]+1e-12)}};cur:=math.pow(2.0,h);if math.abs(cur-1.5)<1e-5{p[i]=probs;break};if cur>1.5{lo=beta;has_lo=true;beta=if has_hi{(beta+hi)/2}else{beta*2}}else{hi=beta;has_hi=true;beta=if has_lo{(beta+lo)/2}else{beta/2}};if it==49{p[i]=probs}}}
  for i in 0..3{for j in 0..3{high[i][j]=math.max((p[i][j]+p[j][i])/6,1e-12)}}
  mut y := [3]f64{};y[0]=0.000030471707975443136;y[1]=-0.00010399841062404956;y[2]=0.00007504511958064573;mut mom := [3]f64{}
  for _ in 0..5{mut total:=0.0;for i in 0..3{for j in 0..3{z:=y[i]-y[j];den[i][j]=if i==j{1.0}else{1+z*z};q[i][j]=if i==j{0.0}else{1/den[i][j]};total+=q[i][j]}};for i in 0..3{for j in 0..3{q[i][j]=if total==0{if i==j{0.0}else{1.0/6}}else{q[i][j]/total};q[i][j]=math.max(q[i][j],1e-12)}};mut g:=[3]f64{};for i in 0..3{for j in 0..3{g[i]+=(high[i][j]-q[i][j])*(1/den[i][j])*(y[i]-y[j])};g[i]*=4};for i in 0..3{mom[i]=0.5*mom[i]-10*g[i];y[i]+=mom[i]}}
  for i in 0..3{out[i]=y[i]};return 3
 }
}
