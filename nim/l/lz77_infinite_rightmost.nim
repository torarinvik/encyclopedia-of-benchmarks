const MaxText = 64
const MaxInput = 66
const MaxOutput = 1536
proc put64(outp: ptr UncheckedArray[uint8], at: int, value: int64) =
  let bits=cast[uint64](value)
  for i in 0..<8: outp[at+i]=uint8((bits shr (8*i)) and 255)
proc lz77_infinite_rightmost*(input:ptr UncheckedArray[int64],len:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"lz77_infinite_rightmost".} =
  if input.isNil or len<1 or len>csize_t(MaxInput):return -1
  let n64=input[0];if n64<0 or n64>MaxText:return -1
  let n=int(n64);if len!=csize_t(n+1):return -1
  for i in 0..<n:if input[i+1]<32 or input[i+1]>126:return -1
  var staged:array[MaxOutput,uint8];var tokens=0;var q=0
  while q<n:
    var bl=0;var bp=0;var found=false
    for p in 0..<q:
      var l=0;while q+l<n and input[p+l+1]==input[q+l+1]:inc l
      if l>bl or (l==bl and l>0 and (not found or p>bp)):bl=l;bp=p;found=true
    let sourcePos=if found:int64(bp) else:0'i64
    let np=q+bl;let ch=if np<n:input[np+1] else:0'i64;let at=tokens*24
    put64(addr staged[0],at,sourcePos);put64(addr staged[0],at+8,int64(bl));put64(addr staged[0],at+16,ch);inc tokens
    q=if ch!=0:np+1 else:np
  let bytes=tokens*24
  if output.isNil or capacity<csize_t(bytes):return -2
  for i in 0..<bytes:output[i]=staged[i]
  int64(bytes)
