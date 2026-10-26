import std/math
const MaxN=64
proc tsvc_s441_s443_d_sign_branch_updates*(x:ptr UncheckedArray[float64],l:csize_t,y:ptr UncheckedArray[float64],cap:csize_t):int64 {.cdecl,exportc:"tsvc_s441_s443_d_sign_branch_updates".}=
 if x.isNil or l<7 or l>259:return -1
 let rawMode=x[0];let rn=x[1];let rp=x[2]
 if not rawMode.isFinite or rawMode!=floor(rawMode) or (rawMode!=0 and rawMode!=1) or not rn.isFinite or rn!=floor(rn) or rn<1 or rn>64 or not rp.isFinite or rp!=floor(rp) or rp<1 or rp>8:return -1
 let mode=int(rawMode);let n=int(rn);let passes=int(rp);if l!=csize_t(3+4*n):return -1
 for i in 3..<int(l):if not x[i].isFinite or x[i]!=floor(x[i]) or abs(x[i])>1:return -1
 if y.isNil or cap<csize_t(n):return -2
 var a:array[MaxN,float64];let b=3+n;let c=3+2*n;let d=3+3*n;for i in 0..<n:a[i]=x[3+i]
 for pass in 0..<passes:
  for i in 0..<n:
   if mode==0:
    if x[d+i]<0:a[i]+=x[b+i]*x[c+i]
    elif x[d+i]==0:a[i]+=x[b+i]*x[b+i]
    else:a[i]+=x[c+i]*x[c+i]
   elif x[d+i]<=0:a[i]+=x[b+i]*x[c+i]
   else:a[i]+=x[b+i]*x[b+i]
 for i in 0..<n:y[i]=a[i]
 int64(n)
