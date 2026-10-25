const MaxWordBytes = 64
proc upperAscii(c: uint32): uint32 =
  if c >= 97'u32 and c <= 122'u32: c - 32'u32 else: c
proc cbench_ispell_hash*(values: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl,exportc:"cbench_ispell_hash".} =
  if values == nil or length == 0 or length > csize_t(MaxWordBytes + 1): return -1
  let tableSize = values[0]
  if tableSize < 1 or tableSize > 2147483647: return -1
  let count = int(length) - 1
  for i in 0 ..< count:
    if values[i + 1] < 1 or values[i + 1] > 127: return -1
  var h = 0'u32
  let initial = min(count, 4)
  for i in 0 ..< initial: h = (h shl 8) or upperAscii(uint32(values[i + 1]))
  for i in initial ..< count:
    h = (h shl 5) or (h shr 27)
    h = h xor upperAscii(uint32(values[i + 1]))
  int64(uint64(h) mod uint64(tableSize))
