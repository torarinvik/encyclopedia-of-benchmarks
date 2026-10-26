import std/math
const MaxN=64
proc tsvc_s2710_nested_scalar_vector_branch_update*(x:ptr UncheckedArray[float64],l:csize_t,y:ptr UncheckedArray[float64],cap:csize_t):int64 {.cdecl,exportc:"tsvc_s2710_nested_scalar_vector_branch_update".}=
 if x.isNil or l<58 or l>323:return -1
 let rn=x[0];let rp=x[1];let scalar=x[2]
 if not rn.isFinite or rn!=floor(rn) or rn<11 or rn>64 or not rp.isFinite or rp!=floor(rp) or rp<1 or rp>8 or not scalar.isFinite or scalar!=floor(scalar) or abs(scalar)>1:return -1
 let n=int(rn);let passes=int(rp)
 if l!=csize_t(3+5*n):return -1
 for i in 3..<int(l):if not x[i].isFinite or x[i]!=floor(x[i]) or abs(x[i])>1:return -1
 if y.isNil or cap<csize_t(3*n):return -2
 var a,b,c:array[MaxN,float64]
 for i in 0..<n:a[i]=x[3+i];b[i]=x[3+n+i];c[i]=x[3+2*n+i]
 for pass in 0..<passes:
  for i in 0..<n:
   let d=x[3+3*n+i];let e=x[3+4*n+i]
   if a[i]>b[i]:
    a[i]+=b[i]*d
    c[i]+=d*d
   else:
    b[i]=a[i]+e*e
    if scalar>0:
     c[i]=a[i]+d*d
    else:
     c[i]+=e*e
 for i in 0..<n:y[i]=a[i];y[n+i]=b[i];y[2*n+i]=c[i]
 int64(3*n)
