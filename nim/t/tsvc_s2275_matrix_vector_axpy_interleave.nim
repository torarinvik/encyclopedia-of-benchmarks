import std/math
const MaxN=8
proc tsvc_s2275_matrix_vector_axpy_interleave*(x:ptr UncheckedArray[float64],l:csize_t,y:ptr UncheckedArray[float64],cap:csize_t):int64 {.cdecl,exportc:"tsvc_s2275_matrix_vector_axpy_interleave".}=
 if x.isNil or l<9 or l>226:return -1
 let rn=x[0];let rp=x[1]
 if not rn.isFinite or rn!=floor(rn) or rn<1 or rn>8 or not rp.isFinite or rp!=floor(rp) or rp<1 or rp>8:return -1
 let n=int(rn);let passes=int(rp);let ms=n*n;let outCount=ms+n
 if l!=csize_t(2+3*ms+4*n):return -1
 for i in 2..<int(l):if not x[i].isFinite or x[i]!=floor(x[i]) or abs(x[i])>1:return -1
 if y.isNil or cap<csize_t(outCount):return -2
 var aa:array[MaxN*MaxN,float64];var a:array[MaxN,float64];let bb=2+ms;let cc=2+2*ms;let vec=2+3*ms
 for i in 0..<ms:aa[i]=x[2+i]
 for i in 0..<n:a[i]=x[vec+i]
 for pass in 0..<passes:
  for i in 0..<n:
   for j in 0..<n:
    let k=j*n+i;aa[k]=aa[k]+x[bb+k]*x[cc+k]
   a[i]=x[vec+n+i]+x[vec+2*n+i]*x[vec+3*n+i]
 for i in 0..<ms:y[i]=aa[i]
 for i in 0..<n:y[ms+i]=a[i]
 int64(outCount)
