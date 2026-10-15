## Return reference events and final cache order (MRU first).
proc putI64Le(output: ptr UncheckedArray[uint8], index: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0..<8: output[index*8+b] = uint8((bits shr (8*b)) and 0xFF'u64)
proc lru_page_reference*(input: ptr UncheckedArray[int64], length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc:"lru_page_reference".} =
  if input.isNil or length < 2: return -1
  let c64=input[0];let n64=input[1]
  if c64<1 or c64>64 or (c64 and (c64-1))!=0 or n64<0 or n64>256 or length!=csize_t(n64+2):return -1
  let c=int(c64);let n=int(n64)
  for i in 0..<n: if input[2+i]<0 or input[2+i]>1_000_000:return -1
  var cache:array[64,int64];var events:array[512,int64];var used=0
  for i in 0..<n:
    let page=input[2+i];var p=0
    while p<used and cache[p]!=page:inc p
    var evicted:int64 = -1
    if p<used:
      var j=p
      while j>0:cache[j]=cache[j-1];dec j
      cache[0]=page;events[2*i]=1
    else:
      if used==c:evicted=cache[used-1];dec used
      var j=used
      while j>0:cache[j]=cache[j-1];dec j
      cache[0]=page;inc used;events[2*i]=0
    events[2*i+1]=evicted
  let words=2*n+2+used
  if output.isNil or capacity<csize_t(words*8):return -2
  putI64Le(output,0,int64(n))
  for i in 0..<2*n:putI64Le(output,i+1,events[i])
  putI64Le(output,2*n+1,int64(used))
  for i in 0..<used:putI64Le(output,2*n+2+i,cache[i])
  int64(words*8)
