import std/math
const MaxN=64
proc tsvc_s2251_carried_scalar_expansion*(x:ptr UncheckedArray[float64],l:csize_t,y:ptr UncheckedArray[float64],c:csize_t):int64 {.cdecl,exportc:"tsvc_s2251_carried_scalar_expansion".}=
 if x.isNil or l<6 or l>321:return -1
 let r=x[0]
 if not r.isFinite or r!=floor(r) or r<1 or r>64:return -1
 let n=int(r)
 if l!=csize_t(1+5*n):return -1
 for i in 1..<int(l):if not x[i].isFinite or x[i]!=floor(x[i]) or abs(x[i])>1:return -1
 if y.isNil or c<csize_t(2*n):return -2
 var a,b:array[MaxN,float64];var s=0.0
 for i in 0..<n:a[i]=s*x[1+4*n+i];s=x[1+n+i]+x[1+2*n+i];b[i]=a[i]+x[1+3*n+i]
 for i in 0..<n:y[i]=a[i];y[n+i]=b[i]
 int64(2*n)
