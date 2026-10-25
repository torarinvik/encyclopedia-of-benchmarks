## Independent bounded ROP3 profile. Full AFPL v5 terms are in package LICENSE.txt.
proc cbench_ghostscript_rop3*(values: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "cbench_ghostscript_rop3".} =
  if length > 5 or (length != 0 and values == nil): return -1
  if length != 4: return -1
  for i in 0 ..< 3:
    if values[i] < 0 or values[i] > 4_294_967_295'i64: return -1
  if values[3] < 0 or values[3] > 255: return -1
  let d = uint64(values[0]); let s = uint64(values[1])
  let t = uint64(values[2]); let code = uint64(values[3])
  var result = 0'u64
  for bit in 0 ..< 32:
    let index = ((t shr bit) and 1'u64) shl 2 or ((s shr bit) and 1'u64) shl 1 or ((d shr bit) and 1'u64)
    if ((code shr int(index)) and 1'u64) != 0: result = result or (1'u64 shl bit)
  int64(result)
