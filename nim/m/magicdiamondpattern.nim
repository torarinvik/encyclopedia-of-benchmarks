const emptyPattern = "       ...       ....        nothing printing :("
proc magicdiamondpattern*(n: int64, output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "magicdiamondpattern".} =
  if n > 45: return -1
  if n <= 0:
    if output.isNil or capacity < csize_t(emptyPattern.len): return -2
    for i,ch in emptyPattern: output[i]=uint8(ord(ch))
    return int64(emptyPattern.len)
  let side=int(n);let required=3*side*side+4*side
  if output.isNil or capacity<csize_t(required): return -2
  var p=0
  for i in 0..<side:
    for _ in 0..<side-i-1: output[p]=uint8(' ');inc p
    for _ in 0..<i+1: output[p]=uint8('*');inc p;output[p]=uint8(' ');inc p
    output[p]=10;inc p
  for i in countdown(side,1):
    for _ in 0..<i: output[p]=uint8('*');inc p;output[p]=uint8(' ');inc p
    output[p]=10;inc p
    for _ in 0..<side-i+1: output[p]=uint8(' ');inc p
  int64(p)
