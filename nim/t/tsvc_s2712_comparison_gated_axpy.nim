import std/math
const MaxN=64
proc tsvc_s2712_comparison_gated_axpy*(x:ptr UncheckedArray[float64],l:csize_t,y:ptr UncheckedArray[float64],cap:csize_t):int64 {.cdecl,exportc:"tsvc_s2712_comparison_gated_axpy".}=
 if x.isNil or l<5 or l>194:return -1
 let rn=x[0];let rp=x[1]
 if not rn.isFinite or rn!=floor(rn) or rn<1 or rn>64 or not rp.isFinite or rp!=floor(rp) or rp<1 or rp>8:return -1
 let n=int(rn);let passes=int(rp)
 if l!=csize_t(2+3*n):return -1
 for i in 2..<int(l):if not x[i].isFinite or x[i]!=floor(x[i]) or abs(x[i])>2:return -1
 if y.isNil or cap<csize_t(n):return -2
 var a:array[MaxN,float64];for i in 0..<n:a[i]=x[2+i]
 for pass in 0..<passes:
  for i in 0..<n:
   let b=x[2+n+i]
   if a[i]>b:a[i]+=b*x[2+2*n+i]
 for i in 0..<n:y[i]=a[i]
 int64(n)
