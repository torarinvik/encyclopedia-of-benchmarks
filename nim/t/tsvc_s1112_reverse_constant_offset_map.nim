# Clean-room TSVC s1112 profile; see package rights note.
proc tsvc_s1112_reverse_constant_offset_map*(input:ptr UncheckedArray[int64],length:csize_t,out:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"tsvc_s1112_reverse_constant_offset_map".}=
 if input.isNil or length<3 or length>129:return -1
 if input[0]<1 or input[0]>64:return -1
 let n=int(input[0]);if length!=csize_t(1+2*n):return -1
 var a:array[64,int64];var b:array[64,int64]
 for i in 0..<n:let x=input[1+i];let y=input[1+n+i];if x< -2 or x>2 or y< -2 or y>2:return -1;a[i]=x;b[i]=y
 if out.isNil or capacity<csize_t(8*n):return -2
 for i in countdown(n-1,0):a[i]=b[i]+1
 for i in 0..<n:var bits=cast[uint64](a[i]);for j in 0..<8:out[8*i+j]=uint8(bits and 255'u64);bits=bits shr 8
 int64(n)
