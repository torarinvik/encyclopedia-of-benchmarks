# Clean-room TSVC s115 profile; see package rights note.
proc put64(out:ptr UncheckedArray[uint8],p:int,v:int64)=
 var b=cast[uint64](v)
 for k in 0..<8:out[p+k]=uint8(b and 255'u64);b=b shr 8
proc tsvc_s115_upper_triangular_saxpy_elimination*(input:ptr UncheckedArray[int64],length:csize_t,out:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"tsvc_s115_upper_triangular_saxpy_elimination".}=
 if input.isNil or length<8 or length>58:return -1
 if input[0]<2 or input[0]>7 or input[1]<1 or input[1]>3:return -1
 let n=int(input[0]);let passes=int(input[1]);if length!=csize_t(2+n+n*n):return -1
 var a:array[8,int64];var m:array[64,int64]
 for i in 0..<n:let x=input[2+i];if x< -1 or x>1:return -1;a[i]=x
 for i in 0..<n*n:let x=input[2+n+i];if x< -1 or x>1:return -1;m[i]=x
 if out.isNil or capacity<csize_t(8*n):return -2
 for p in 0..<passes:
  for j in 0..<n:
   for i in j+1..<n:a[i]-=m[j*n+i]*a[j]
 for i in 0..<n:put64(out,8*i,a[i])
 int64(n)
