const MaxN = 256
const ValueLimit = 1_000_000'i64

proc good_pairs*(packed: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "good_pairs".} =
  if packed == nil or length == 0 or length > csize_t(MaxN + 1): return -1
  let n = packed[0]
  if n < 0 or n > MaxN or length != csize_t(n) + 1: return -1
  for i in 0 ..< int(n):
    if packed[i + 1] < -ValueLimit or packed[i + 1] > ValueLimit: return -1
  var count = 0'i64
  for i in 0 ..< int(n):
    for j in (i + 1) ..< int(n):
      if packed[i + 1] == packed[j + 1]: inc count
  count
