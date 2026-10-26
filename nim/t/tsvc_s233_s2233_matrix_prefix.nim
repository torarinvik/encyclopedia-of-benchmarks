# Clean-room TSVC s233/s2233 profiles; see package rights note.
proc tsvc_s233_s2233_matrix_prefix*(input:ptr UncheckedArray[int64],length:csize_t,out:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"tsvc_s233_s2233_matrix_prefix".}=
 if input.isNil or length<14 or length>194:return -1
 let nr=input[0];let mode=input[1];if nr<2 or nr>8 or (mode!=0 and mode!=1):return -1
 let n=int(nr);let nn=n*n;if length!=csize_t(2+3*nn):return -1
 var a,b,c:array[64,int64]
 for i in 0..<nn:let x=input[2+i];let y=input[2+nn+i];let z=input[2+2*nn+i];if x< -1 or x>1 or y< -1 or y>1 or z< -1 or z>1:return -1;a[i]=x;b[i]=y;c[i]=z
 if out.isNil or capacity<csize_t(16*nn):return -2
 for i in 1..<n:
  for j in 1..<n:a[j*n+i]=a[(j-1)*n+i]+c[j*n+i]
 if mode==0:
  for i in 1..<n:
   for j in 1..<n:b[j*n+i]=b[j*n+i-1]+c[j*n+i]
 else:
  for i in 1..<n:
   for j in 1..<n:b[i*n+j]=b[(i-1)*n+j]+c[i*n+j]
 for i in 0..<nn:var x=cast[uint64](a[i]);var y=cast[uint64](b[i]);for k in 0..<8:out[8*i+k]=uint8(x and 255'u64);x=x shr 8;out[8*(nn+i)+k]=uint8(y and 255'u64);y=y shr 8
 int64(2*nn)
