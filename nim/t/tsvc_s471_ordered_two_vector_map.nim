## Clean-room TSVC s471 profile; see package rights note.
const MaxN=32
const MaxInputLength=130
proc put64(out:ptr UncheckedArray[uint8],pos:int,value:int64)=
 var bits=cast[uint64](value)
 for j in 0..<8:out[pos+j]=uint8(bits and 255'u64);bits=bits shr 8
proc tsvc_s471_ordered_two_vector_map*(input:ptr UncheckedArray[int64],inputLength:csize_t,out:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"tsvc_s471_ordered_two_vector_map".}=
 if input.isNil or inputLength<6 or inputLength>MaxInputLength:return -1
 if input[0]<1 or input[0]>MaxN or input[1]<1 or input[1]>4 or inputLength!=csize_t(2+4*input[0]):return -1
 let n=int(input[0]);let passes=int(input[1]);var x:array[MaxN,float64];var b:array[MaxN,float64];var c:array[MaxN,float64];var d:array[MaxN,float64];var e:array[MaxN,float64]
 for i in 0..<n:
  let bv=input[2+i];let cv=input[2+n+i];let dv=input[2+2*n+i];let ev=input[2+3*n+i]
  if bv< -2 or bv>2 or cv< -2 or cv>2 or dv< -2 or dv>2 or ev< -2 or ev>2:return -1
  b[i]=float64(bv);c[i]=float64(cv);d[i]=float64(dv);e[i]=float64(ev)
 let bytes=16*n;if out.isNil or capacity<csize_t(bytes):return -2
 for p in 0..<passes:
  for i in 0..<n:x[i]=b[i]+d[i]*d[i];b[i]=c[i]+d[i]*e[i]
 for i in 0..<n:put64(out,8*i,int64(x[i]));put64(out,8*(n+i),int64(b[i]))
 int64(bytes)
