# Clean-room TSVC s118 profile; see package rights note.
proc tsvc_s118_triangular_convolution_recurrence*(input:ptr UncheckedArray[int64],length:csize_t,out:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"tsvc_s118_triangular_convolution_recurrence".}=
 if input.isNil or length<8 or length>74:return -1
 let nr=input[0];let pr=input[1];if nr<2 or nr>8 or pr<1 or pr>4:return -1
 let n=int(nr);if length!=csize_t(2+n+n*n):return -1
 var a:array[8,int64];var b:array[64,int64]
 for i in 0..<n:let x=input[2+i];if x< -1 or x>1:return -1;a[i]=x
 for i in 0..<n*n:let x=input[2+n+i];if x< -1 or x>1:return -1;b[i]=x
 if out.isNil or capacity<csize_t(8*n):return -2
 for p in 0..<int(pr):
  for i in 1..<n:
   for j in 0..<i:a[i]+=b[j*n+i]*a[i-j-1]
 for i in 0..<n:var bits=cast[uint64](a[i]);for j in 0..<8:out[8*i+j]=uint8(bits and 255'u64);bits=bits shr 8
 int64(n)
