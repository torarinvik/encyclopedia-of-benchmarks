# Clean-room TSVC s1111 profile; see package rights note.
const MaxN=32
proc put64(out:ptr UncheckedArray[uint8],pos:int,value:int64)=
 var bits=cast[uint64](value)
 for j in 0..<8:out[pos+j]=uint8(bits and 255'u64);bits=bits shr 8
proc tsvc_s1111_stride_two_polynomial_map*(input:ptr UncheckedArray[int64],length:csize_t,out:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"tsvc_s1111_stride_two_polynomial_map".}=
 if input.isNil or length<6 or length>161:return -1
 if input[0]<1 or input[0]>MaxN:return -1
 let n=int(input[0]);if length!=csize_t(1+5*n):return -1
 var a:array[64,int64];var b:array[32,int64];var c:array[32,int64];var d:array[32,int64];var off=1
 for i in 0..<2*n:let x=input[off+i];if x< -2 or x>2:return -1;a[i]=x
 off+=2*n
 for i in 0..<n:let x=input[off+i];if x< -2 or x>2:return -1;b[i]=x
 off+=n
 for i in 0..<n:let x=input[off+i];if x< -2 or x>2:return -1;c[i]=x
 off+=n
 for i in 0..<n:let x=input[off+i];if x< -2 or x>2:return -1;d[i]=x
 let bytes=16*n;if out.isNil or capacity<csize_t(bytes):return -2
 for i in 0..<n:a[2*i]=c[i]*b[i]+d[i]*b[i]+c[i]*c[i]+d[i]*b[i]+d[i]*c[i]
 for i in 0..<2*n:put64(out,8*i,a[i])
 int64(2*n)
