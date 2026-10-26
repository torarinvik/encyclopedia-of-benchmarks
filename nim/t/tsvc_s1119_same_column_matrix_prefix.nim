# Clean-room TSVC s1119 profile; see package rights note.
proc tsvc_s1119_same_column_matrix_prefix*(input:ptr UncheckedArray[int64],length:csize_t,out:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"tsvc_s1119_same_column_matrix_prefix".}=
 if input.isNil or length<10 or length>130:return -1
 let nr=input[0];let pr=input[1];if nr<2 or nr>8 or pr<1 or pr>4:return -1
 let n=int(nr);let nn=n*n;if length!=csize_t(2+2*nn):return -1
 var a:array[64,int64];var b:array[64,int64]
 for i in 0..<nn:let x=input[2+i];let y=input[2+nn+i];if x< -1 or x>1 or y< -1 or y>1:return -1;a[i]=x;b[i]=y
 if out.isNil or capacity<csize_t(8*nn):return -2
 for p in 0..<int(pr):
  for i in 1..<n:
   for j in 0..<n:a[i*n+j]=a[(i-1)*n+j]+b[i*n+j]
 for i in 0..<nn:var bits=cast[uint64](a[i]);for j in 0..<8:out[8*i+j]=uint8(bits and 255'u64);bits=bits shr 8
 int64(nn)
