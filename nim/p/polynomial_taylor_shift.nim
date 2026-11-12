const
  Modulus = 998_244_353'i64
  MaxN = 64
  MaxInput = 66
  Capacity = 64

type Shifted = array[Capacity, int64]

proc storeLe(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc polynomial_taylor_shift*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "polynomial_taylor_shift".} =
  if input.isNil or length < csize_t(3) or length > csize_t(MaxInput): return -1
  let nValue = input[0]
  let shift = input[1]
  if nValue < 1 or nValue > MaxN.int64: return -1
  let n = nValue.int
  if length != csize_t(n + 2) or shift < 0 or shift >= Modulus: return -1
  for i in 0 ..< n:
    if input[i + 2] < 0 or input[i + 2] >= Modulus: return -1

  let bytes = 8 * n
  if output.isNil or capacity < csize_t(bytes): return -2
  var shifted: Shifted
  var processed = 0
  var source = n
  while source > 0:
    dec source
    var degree = processed
    while degree > 0:
      shifted[degree] = (shifted[degree] * shift + shifted[degree - 1]) mod Modulus
      dec degree
    shifted[0] = (shifted[0] * shift + input[source + 2]) mod Modulus
    inc processed
  for i in 0 ..< n: storeLe(output, 8 * i, shifted[i])
  int64(bytes)
