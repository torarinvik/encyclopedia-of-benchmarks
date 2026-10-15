## Emit the median after each insertion into a fixed-width trailing window.
proc putF64Le(output:ptr UncheckedArray[uint8],offset:int,value:float64)=
  let bits=cast[uint64](value)
  for b in 0..<8:output[offset+b]=uint8((bits shr (8*b)) and 0xFF'u64)
proc windowed_median*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"windowed_median".}=
  if input.isNil or length<3:return -1
  let w64=input[0];let n64=input[1];if w64<1 or w64>64 or n64<1 or n64>128:return -1
  let w=int(w64);let n=int(n64);if length!=csize_t(n+2):return -1
  for i in 0..<n:if input[2+i]< -1_000_000 or input[2+i]>1_000_000:return -1
  if capacity<csize_t(n*8) or output.isNil:return -2
  var sorted:array[64,int64];var active=0
  for i in 0..<n:
    if i>=w:
      let old=input[2+i-w];var p=0
      while p<active and sorted[p]!=old:inc p
      if p==active:return -1
      for j in p+1..<active:sorted[j-1]=sorted[j]
      dec active
    let value=input[2+i];var p=0
    while p<active and sorted[p]<value:inc p
    var j=active
    while j>p:sorted[j]=sorted[j-1];dec j
    sorted[p]=value;inc active
    let median:float32=if active mod 2==1:float32(sorted[active div 2]) else:0.5'f32*float32(sorted[active div 2-1])+0.5'f32*float32(sorted[active div 2])
    putF64Le(output,i*8,float64(median))
  int64(n*8)
