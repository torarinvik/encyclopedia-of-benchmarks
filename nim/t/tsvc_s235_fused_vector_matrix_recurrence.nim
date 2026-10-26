# Clean-room TSVC s235 profile; see package rights note.
proc tsvc_s235_fused_vector_matrix_recurrence*(input:ptr UncheckedArray[int64],length:csize_t,out:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"tsvc_s235_fused_vector_matrix_recurrence".}=
 if input.isNil or length<15 or length>153:return -1
 let nr=input[0];if nr<2 or nr>8:return -1
 let n=int(nr);let nn=n*n;if length!=csize_t(1+3*n+2*nn):return -1
 var a:array[8,int64];var b:array[8,int64];var c:array[8,int64];var aa:array[64,int64];var bb:array[64,int64];var p=1
 for i in 0..<n:let x=input[p];inc p;if x< -1 or x>1:return -1;a[i]=x
 for i in 0..<n:let x=input[p];inc p;if x< -1 or x>1:return -1;b[i]=x
 for i in 0..<n:let x=input[p];inc p;if x< -1 or x>1:return -1;c[i]=x
 for i in 0..<nn:let x=input[p];inc p;if x< -1 or x>1:return -1;aa[i]=x
 for i in 0..<nn:let x=input[p];inc p;if x< -1 or x>1:return -1;bb[i]=x
 if out.isNil or capacity<csize_t(8*(n+nn)):return -2
 for col in 0..<n:a[col]+=b[col]*c[col];for row in 1..<n:let k=row*n+col;aa[k]=aa[k-n]+bb[k]*a[col]
 for i in 0..<n:var x=cast[uint64](a[i]);for k in 0..<8:out[8*i+k]=uint8(x and 255'u64);x=x shr 8
 for i in 0..<nn:var x=cast[uint64](aa[i]);for k in 0..<8:out[8*(n+i)+k]=uint8(x and 255'u64);x=x shr 8
 int64(n+nn)
