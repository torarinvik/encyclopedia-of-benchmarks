const MaxItems = 12
const MaxSafe = 9_007_199_254_740_991'i64

proc put32(output: ptr UncheckedArray[uint8], pos: var int, value: uint32) =
  var bits = value
  for _ in 0 ..< 4:
    output[pos] = uint8(bits and 255)
    inc pos
    bits = bits shr 8

proc put64(output: ptr UncheckedArray[uint8], pos: var int, value: int64) =
  var bits = cast[uint64](value)
  for _ in 0 ..< 8:
    output[pos] = uint8(bits and 255)
    inc pos
    bits = bits shr 8

proc generate_sub_sets*(input: ptr UncheckedArray[int64], length: csize_t,
                        output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "generate_sub_sets".} =
  if input == nil or length < 1 or length > MaxItems + 1: return -1
  let nArg = input[0]
  if nArg < 0 or nArg > MaxItems: return -1
  let n = int(nArg)
  if length != csize_t(n + 1): return -1
  for i in 0 ..< n:
    if input[i + 1] < -MaxSafe or input[i + 1] > MaxSafe: return -1
  let subsets = 1 shl n
  let totalItems = if n == 0: 0 else: n * (subsets div 2)
  let needed = 4 + 4 * subsets + 8 * totalItems
  if output == nil or capacity < csize_t(needed): return -2
  var pos = 0
  put32(output, pos, uint32(subsets))
  for mask in 0 ..< subsets:
    var count = 0'u32
    for j in 0 ..< n:
      if (mask and (1 shl j)) != 0: inc count
    put32(output, pos, count)
    for j in 0 ..< n:
      if (mask and (1 shl j)) != 0: put64(output, pos, input[j + 1])
  int64(pos)
