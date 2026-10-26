# Clean-room TSVC s1113 profile; see package rights note.
proc put64(out:ptr UncheckedArray[uint8],p:int,v:int64)=
 var b=cast[uint64](v)
 for j in 0..<8:out[p+j]=uint8(b and 255'u64);b=b shr 8
proc tsvc_s1113_feedback_anchor_add*(input:ptr UncheckedArray[int64],length:csize_t,out:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"tsvc_s1113_feedback_anchor_add".}=
 if input.isNil or length<3 or length>129:return -1
 if input[0]<1 or input[0]>64:return -1
 let n=int(input[0]);if length!=csize_t(1+2*n):return -1
 var a:array[64,int64];var b:array[64,int64]
 for i in 0..<n:let x=input[1+i];let y=input[1+n+i];if x< -2 or x>2 or y< -2 or y>2:return -1;a[i]=x;b[i]=y
 if out.isNil or capacity<csize_t(8*n):return -2
 for i in 0..<n:a[i]=a[n div 2]+b[i]
 for i in 0..<n:put64(out,8*i,a[i])
 int64(n)
