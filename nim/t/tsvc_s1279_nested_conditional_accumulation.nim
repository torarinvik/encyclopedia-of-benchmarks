import std/math
const MaxN=64
proc tsvc_s1279_nested_conditional_accumulation*(x:ptr UncheckedArray[float64],l:csize_t,y:ptr UncheckedArray[float64],cap:csize_t):int64 {.cdecl,exportc:"tsvc_s1279_nested_conditional_accumulation".}=
 if x.isNil or l<7 or l>322:return -1
 let rn=x[0];let rp=x[1]
 if not rn.isFinite or rn!=floor(rn) or rn<1 or rn>64 or not rp.isFinite or rp!=floor(rp) or rp<1 or rp>8:return -1
 let n=int(rn);let passes=int(rp);if l!=csize_t(2+5*n):return -1
 for i in 2..<int(l):if not x[i].isFinite or x[i]!=floor(x[i]) or abs(x[i])>1:return -1
 if y.isNil or cap<csize_t(n):return -2
 var c:array[MaxN,float64];for i in 0..<n:c[i]=x[2+2*n+i]
 for pass in 0..<passes:
  for i in 0..<n:
   let a=x[2+i];let b=x[2+n+i]
   if a<0:
    if b>a:c[i]+=x[2+3*n+i]*x[2+4*n+i]
 for i in 0..<n:y[i]=c[i]
 int64(n)
