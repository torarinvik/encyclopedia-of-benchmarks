import std/math
const MaxN=40
proc tsvc_s351_direct_unrolled_saxpy*(x:ptr UncheckedArray[float64],l:csize_t,y:ptr UncheckedArray[float64],cap:csize_t):int64 {.cdecl,exportc:"tsvc_s351_direct_unrolled_saxpy".}=
 if x.isNil or l<12 or l>82:return -1
 let rd=x[0]
 if not rd.isFinite or rd!=floor(rd) or rd<5 or rd>40:return -1
 let n=int(rd)
 if n mod 5!=0 or l!=csize_t(2+2*n):return -1
 for i in 1..<int(l):if not x[i].isFinite or x[i]!=floor(x[i]) or abs(x[i])>1:return -1
 if y.isNil or cap<csize_t(n):return -2
 var a:array[MaxN,float64]
 for i in 0..<n:a[i]=x[2+i]
 let alpha=x[1]
 for base in countup(0,n-1,5):
  let p0=alpha*x[2+n+base]
  a[base]=a[base]+p0
  let p1=alpha*x[2+n+base+1]
  a[base+1]=a[base+1]+p1
  let p2=alpha*x[2+n+base+2]
  a[base+2]=a[base+2]+p2
  let p3=alpha*x[2+n+base+3]
  a[base+3]=a[base+3]+p3
  let p4=alpha*x[2+n+base+4]
  a[base+4]=a[base+4]+p4
 for i in 0..<n:y[i]=a[i]
 int64(n)
