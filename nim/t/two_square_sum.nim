const MaxQ = 8
const MaxN = 10_000'i64
const MaxOutputBytes = 6_496

proc integerSqrt(value: int64): int64 =
  var low = 0'i64
  var high = value + 1
  while high - low > 1:
    let middle = low + (high - low) div 2
    if middle * middle <= value: low = middle
    else: high = middle
  low

proc writeU32(output: ptr UncheckedArray[uint8], offset: int, value: uint32) =
  output[offset] = uint8(value and 0xff'u32)
  output[offset + 1] = uint8((value shr 8) and 0xff'u32)
  output[offset + 2] = uint8((value shr 16) and 0xff'u32)
  output[offset + 3] = uint8((value shr 24) and 0xff'u32)

proc two_square_sum*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "two_square_sum".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxQ + 1): return -1
  let q64 = input[0]
  if q64 < 1 or q64 > MaxQ.int64: return -1
  let q = int(q64)
  if int64(length) != q.int64 + 1: return -1

  var numbers: array[MaxQ, int64]
  var counts: array[MaxQ, int]
  var totalPairs = 0
  for query in 0..<q:
    let n = input[query + 1]
    if n < 0 or n > MaxN: return -1
    numbers[query] = n
    var a = 0'i64
    while a * a <= n:
      let remainder = n - a * a
      let b = integerSqrt(remainder)
      if b * b == remainder: counts[query] += 1
      a += 1
    totalPairs += counts[query]

  let required = 4 * (q + 2 * totalPairs)
  if output.isNil or capacity < csize_t(required) or required > MaxOutputBytes: return -2
  var offset = 0
  for query in 0..<q:
    writeU32(output, offset, uint32(counts[query]))
    offset += 4
    let n = numbers[query]
    var a = 0'i64
    while a * a <= n:
      let remainder = n - a * a
      let b = integerSqrt(remainder)
      if b * b == remainder:
        writeU32(output, offset, uint32(a))
        writeU32(output, offset + 4, uint32(b))
        offset += 8
      a += 1
  int64(offset)
