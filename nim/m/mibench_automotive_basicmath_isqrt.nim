proc mibench_automotive_basicmath_isqrt*(input: ptr UncheckedArray[int64],
    length: csize_t): int64 {.cdecl, exportc: "mibench_automotive_basicmath_isqrt".} =
  if input == nil or length != 1: return -1
  if input[0] < 0 or input[0] > 65535: return -1
  var x = uint32(input[0])
  var root = 0'u32
  var remainder = 0'u32
  for step in 0 ..< 32:
    remainder = (remainder shl 2) + (x shr 30)
    x = x shl 2
    root = root shl 1
    let trial = (root shl 1) + 1'u32
    if remainder >= trial:
      remainder -= trial
      inc root
  int64(root)
