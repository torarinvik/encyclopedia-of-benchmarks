proc binary32Ge(a, b: uint32): bool =
  let expA = (a shr 23) and 0xff'u32; let fracA = a and 0x7f_ffff'u32
  let expB = (b shr 23) and 0xff'u32; let fracB = b and 0x7f_ffff'u32
  if (expA == 0xff'u32 and fracA != 0) or (expB == 0xff'u32 and fracB != 0): return false
  let magA = a and 0x7fff_ffff'u32; let magB = b and 0x7fff_ffff'u32
  if magA == 0 and magB == 0: return true
  let negA = (a shr 31) != 0; let negB = (b shr 31) != 0
  if negA != negB: return not negA
  if negA: magA <= magB else: magA >= magB

proc versabench_dbms_valid_index_key*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "versabench_dbms_valid_index_key".} =
  if values == nil or length < 1 or length > 9 or length != 8: return -1
  var bits: array[8, uint32]
  for i in 0 ..< 8:
    if values[i] < 0 or values[i] > 0xffff_ffff'i64: return -1
    bits[i] = uint32(values[i])
  for d in 0 ..< 4:
    if binary32Ge(bits[d], bits[4+d]): return 0
  1
