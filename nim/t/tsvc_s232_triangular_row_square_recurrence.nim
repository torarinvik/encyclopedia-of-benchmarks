# Clean-room TSVC s232 profile; see package rights note.
proc tsvc_s232_triangular_row_square_recurrence*(input:ptr UncheckedArray[int64],length:csize_t,out:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"tsvc_s232_triangular_row_square_recurrence".}=
 if input.isNil or length<9 or length>51:return -1
 let nr=input[0];if nr<2 or nr>5:return -1
 let n=int(nr);let nn=n*n;if length!=csize_t(1+2*nn):return -1
 var a:array[25,int64];var b:array[25,int64]
 for i in 0..<nn:let x=input[1+i];let y=input[1+nn+i];if x< -1 or x>1 or y< -1 or y>1:return -1;a[i]=x;b[i]=y
 if out.isNil or capacity<csize_t(8*nn):return -2
 for j in 1..<n:
  for i in 1..j:let x=a[j*n+i-1];a[j*n+i]=x*x+b[j*n+i]
 for i in 0..<nn:var bits=cast[uint64](a[i]);for k in 0..<8:out[8*i+k]=uint8(bits and 255'u64);bits=bits shr 8
 int64(nn)
