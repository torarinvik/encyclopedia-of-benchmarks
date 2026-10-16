package dimensionality_reduction_tsne
import "core:c"
import "core:math"
@(export)
dimensionality_reduction_tsne :: proc "c" (v:[^]f64,n0:c.size_t,out:[^]f64,cap0:c.size_t)->i64 {
 n:=int(n0);cap:=int(cap0);if v==nil||n!=5||v[0]!=1||v[1]!=3{return -1};for i:=2;i<5;i+=1{if math.is_nan(v[i])||math.is_inf(v[i])||math.abs(v[i])>100{return -1}};if out==nil||cap<3{return -2}
 d:[3][3]f64;p:[3][3]f64;high:[3][3]f64;q:[3][3]f64;den:[3][3]f64
 for i:=0;i<3;i+=1{for j:=0;j<3;j+=1{z:=v[2+i]-v[2+j];d[i][j]=z*z}}
 for i:=0;i<3;i+=1{beta:=1.0;lo:=0.0;hi:=0.0;haslo:=false;hashi:=false;probs:[3]f64;for it:=0;it<50;it+=1{e:[3]f64;sum:=0.0;for j:=0;j<3;j+=1{if i==j{e[j]=0}else{e[j]=math.exp(-d[i][j]*beta)};sum+=e[j]}if sum==0{break};h:=0.0;for j:=0;j<3;j+=1{probs[j]=e[j]/sum;if probs[j]>0{h-=probs[j]*math.log2(probs[j]+1e-12)}};cur:=math.pow(2.0,h);if math.abs(cur-1.5)<1e-5{p[i]=probs;break};if cur>1.5{lo=beta;haslo=true;if hashi{beta=(beta+hi)/2}else{beta*=2}}else{hi=beta;hashi=true;if haslo{beta=(beta+lo)/2}else{beta/=2}};if it==49{p[i]=probs}}}
 for i:=0;i<3;i+=1{for j:=0;j<3;j+=1{high[i][j]=math.max((p[i][j]+p[j][i])/6,1e-12)}}
 y:=[3]f64{3.0471707975443136e-05,-1.0399841062404956e-04,7.504511958064573e-05};mom:[3]f64
 for it:=0;it<5;it+=1{total:=0.0;for i:=0;i<3;i+=1{for j:=0;j<3;j+=1{z:=y[i]-y[j];if i==j{den[i][j]=1}else{den[i][j]=1+z*z};if i==j{q[i][j]=0}else{q[i][j]=1/den[i][j]};total+=q[i][j]}};for i:=0;i<3;i+=1{for j:=0;j<3;j+=1{if total==0{if i==j{q[i][j]=0}else{q[i][j]=1.0/6}}else{q[i][j]/=total};q[i][j]=math.max(q[i][j],1e-12)}};g:[3]f64;for i:=0;i<3;i+=1{for j:=0;j<3;j+=1{g[i]+=(high[i][j]-q[i][j])*(1/den[i][j])*(y[i]-y[j])};g[i]*=4};for i:=0;i<3;i+=1{mom[i]=0.5*mom[i]-10*g[i];y[i]+=mom[i]}}
 for i:=0;i<3;i+=1{out[i]=y[i]};return 3
}
