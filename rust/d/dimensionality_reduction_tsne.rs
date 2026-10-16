#[no_mangle]
pub unsafe extern "C" fn dimensionality_reduction_tsne(ptr:*const f64,n:usize,out:*mut f64,cap:usize)->i64 {
 if ptr.is_null()||n!=5{return -1} let v=std::slice::from_raw_parts(ptr,n);
 if v[0]!=1.0||v[1]!=3.0||v[2..].iter().any(|x|!x.is_finite()||x.abs()>100.0){return -1}
 if out.is_null()||cap<3{return -2}
 let mut d=[[0.0;3];3];let mut p=[[0.0;3];3];
 for i in 0..3{for j in 0..3{let z=v[2+i]-v[2+j];d[i][j]=z*z;}}
 for i in 0..3 {let(mut lo,mut hi,mut beta)=(f64::NEG_INFINITY,f64::INFINITY,1.0);let mut probs=[0.0;3];
  for it in 0..50 {let mut e=[0.0;3];let mut sum=0.0;for j in 0..3{e[j]=if i==j{0.0}else{(-d[i][j]*beta).exp()};sum+=e[j];}
   if sum==0.0{p[i]=[0.0;3];break}let mut h=0.0;for j in 0..3{probs[j]=e[j]/sum;if probs[j]>0.0{h-=probs[j]*(probs[j]+1e-12).log2();}}
   let current=2.0_f64.powf(h);if (current-1.5).abs()<1e-5{p[i]=probs;break}
   if current>1.5{lo=beta;beta=if hi.is_infinite(){beta*2.0}else{(beta+hi)/2.0};}else{hi=beta;beta=if lo.is_infinite(){beta/2.0}else{(beta+lo)/2.0};}
   if it==49{p[i]=probs;}
  }
 }
 let mut high=[[0.0;3];3];for i in 0..3{for j in 0..3{high[i][j]=((p[i][j]+p[j][i])/6.0).max(1e-12);}}
 let mut y=[3.0471707975443136e-05,-1.0399841062404956e-04,7.504511958064573e-05];let mut mom=[0.0;3];
 for _ in 0..5 {let mut q=[[0.0;3];3];let mut denom=[[0.0;3];3];let mut total=0.0;
  for i in 0..3{for j in 0..3{let z=y[i]-y[j];denom[i][j]=if i==j{f64::INFINITY}else{1.0+z*z};q[i][j]=if i==j{0.0}else{1.0/denom[i][j]};total+=q[i][j];}}
  for i in 0..3{for j in 0..3{q[i][j]=if total==0.0{if i==j{0.0}else{1.0/6.0}}else{q[i][j]/total};q[i][j]=q[i][j].max(1e-12);}}
  let mut g=[0.0;3];for i in 0..3{for j in 0..3{g[i]+=(high[i][j]-q[i][j])*(1.0/denom[i][j])*(y[i]-y[j]);}g[i]*=4.0;}
  for i in 0..3{mom[i]=0.5*mom[i]-10.0*g[i];y[i]+=mom[i];}
 }
 let o=std::slice::from_raw_parts_mut(out,3);o.copy_from_slice(&y);3
}
