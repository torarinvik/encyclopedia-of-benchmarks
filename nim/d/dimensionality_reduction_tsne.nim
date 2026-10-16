import std/math
proc dimensionality_reduction_tsne*(v: ptr UncheckedArray[float64], n:csize_t, outp:ptr UncheckedArray[float64], cap:csize_t):int64 {.cdecl,exportc:"dimensionality_reduction_tsne".}=
 if v.isNil or n!=5 or v[0]!=1 or v[1]!=3:return -1
 for i in 2..4:
  if classify(v[i]) in {fcNan,fcInf,fcNegInf} or abs(v[i])>100:return -1
 if outp.isNil or cap<3:return -2
 var d,p,high,q,den:array[3,array[3,float64]]
 for i in 0..2:
  for j in 0..2:
   let z=v[2+i]-v[2+j];d[i][j]=z*z
 for i in 0..2:
  var beta=1.0;var lo=0.0;var hi=0.0;var hasLo=false;var hasHi=false;var probs:array[3,float64]
  for it in 0..49:
   var e:array[3,float64];var total=0.0
   for j in 0..2:
    if i==j: e[j]=0.0
    else: e[j]=exp(-d[i][j]*beta)
    total+=e[j]
   if total==0:break
   var h=0.0
   for j in 0..2:
    probs[j]=e[j]/total
    if probs[j]>0:h-=probs[j]*log2(probs[j]+1e-12)
   let cur=pow(2.0,h)
   if abs(cur-1.5)<1e-5:
    p[i]=probs;break
   if cur>1.5:
    lo=beta;hasLo=true;beta=if hasHi:(beta+hi)/2 else:beta*2
   else:
    hi=beta;hasHi=true;beta=if hasLo:(beta+lo)/2 else:beta/2
   if it==49:p[i]=probs
 for i in 0..2:
  for j in 0..2:high[i][j]=max((p[i][j]+p[j][i])/6,1e-12)
 var y=[3.0471707975443136e-05,-1.0399841062404956e-04,7.504511958064573e-05];var mom:array[3,float64]
 for it in 0..4:
  var total=0.0
  for i in 0..2:
   for j in 0..2:
    let z=y[i]-y[j]
    if i==j: den[i][j]=Inf
    else: den[i][j]=1+z*z
    if i==j: q[i][j]=0.0
    else: q[i][j]=1/den[i][j]
    total+=q[i][j]
  for i in 0..2:
   for j in 0..2:
    if total==0:
     if i==j: q[i][j]=0.0
     else: q[i][j]=1.0/6
    else: q[i][j]=q[i][j]/total
    q[i][j]=max(q[i][j],1e-12)
  var g:array[3,float64]
  for i in 0..2:
   for j in 0..2:g[i]+=(high[i][j]-q[i][j])*(1/den[i][j])*(y[i]-y[j])
   g[i]*=4
  for i in 0..2:mom[i]=0.5*mom[i]-10*g[i];y[i]+=mom[i]
 for i in 0..2:outp[i]=y[i]
 return 3
