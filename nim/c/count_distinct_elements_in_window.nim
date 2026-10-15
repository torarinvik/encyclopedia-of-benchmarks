proc putI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits=cast[uint64](value)
  for b in 0..<8: output[offset+b]=uint8((bits shr (8*b)) and 0xFF'u64)
proc count_distinct_elements_in_window*(input: ptr UncheckedArray[int64], length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "count_distinct_elements_in_window".} =
  if input.isNil or length<3 or input[0]<1 or input[0]>256: return -1
  let n=int(input[0])
  if input[1]<1 or input[1]>int64(n) or length!=csize_t(n+2): return -1
  let k=int(input[1]); let outN=n-k+1
  for i in 0..<n:
    if input[i+2]<int64(low(int32)) or input[i+2]>int64(high(int32)): return -1
  if capacity<csize_t(outN*8) or output.isNil: return -2
  var keys: array[256,int32]
  var counts: array[256,int32]
  var used=0; var distinct:int64=0
  for i in 0..<k:
    let value=int32(input[i+2]); var j=0
    while j<used and keys[j]!=value: inc j
    if j==used: keys[used]=value; inc used
    if counts[j]==0: inc distinct
    inc counts[j]
  putI64Le(output,0,distinct)
  for i in k..<n:
    let incoming=int32(input[i+2]); var j=0
    while j<used and keys[j]!=incoming: inc j
    if j==used: keys[used]=incoming; inc used
    if counts[j]==0: inc distinct
    inc counts[j]
    let outgoing=int32(input[i-k+2]); j=0
    while keys[j]!=outgoing: inc j
    dec counts[j]
    if counts[j]==0: dec distinct
    putI64Le(output,(i-k+1)*8,distinct)
  int64(outN*8)
