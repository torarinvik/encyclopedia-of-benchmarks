## Clean-room implementation of TSVC vtv; see package rights note.
const MaxN=32
const MaxInputLength=66
proc storeI64Le(out:ptr UncheckedArray[uint8],pos:int,value:int64)=
 var bits=cast[uint64](value)
 for j in 0..<8: out[pos+j]=uint8(bits and 255'u64);bits=bits shr 8
proc tsvc_vtv_elementwise_product*(input:ptr UncheckedArray[int64],inputLength:csize_t,out:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"tsvc_vtv_elementwise_product".}=
 if input.isNil or inputLength<4 or inputLength>MaxInputLength:return -1
 if input[0]<1 or input[0]>MaxN or input[1]<1 or input[1]>8 or inputLength!=csize_t(2+2*input[0]):return -1
 let n=int(input[0]);let passes=int(input[1]);var a:array[MaxN,float64];var b:array[MaxN,float64]
 for i in 0..<n:
  let av=input[2+i];let bv=input[2+n+i]
  if av< -2 or av>2 or bv< -2 or bv>2:return -1
  a[i]=float64(av);b[i]=float64(bv)
 let bytes=8*n;if out.isNil or capacity<csize_t(bytes):return -2
 for p in 0..<passes:
  for i in 0..<n:a[i]*=b[i]
 for i in 0..<n:storeI64Le(out,8*i,int64(a[i]))
 int64(bytes)
