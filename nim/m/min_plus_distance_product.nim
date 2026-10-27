const MaxInput = 130
const MaxOutput = 512
const Inf = 1_000_000'i64

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc min_plus_distance_product*(input: ptr UncheckedArray[int64], length: csize_t,
                                output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "min_plus_distance_product".} =
  if input.isNil or length < 4 or length > MaxInput: return -1
  let n0 = input[0]
  let m0 = input[1]
  if n0 < 1 or n0 > 8 or m0 < 1 or m0 > 8: return -1
  let n = int(n0)
  let m = int(m0)
  if int(length) != 2 + 2 * n * m: return -1
  for i in 2 ..< int(length):
    if input[i] < 0 or (input[i] > 1000 and input[i] != Inf): return -1
  let bytes = 8 * n * n
  if bytes > MaxOutput: return -1
  if output.isNil or int(capacity) < bytes: return -2
  var result: array[64, int64]
  for i in 0 ..< n:
    for j in 0 ..< n:
      var best = Inf
      for k in 0 ..< m:
        let x = input[2 + i * m + k]
        let y = input[2 + n * m + k * n + j]
        if x != Inf and y != Inf and x + y < best: best = x + y
      result[i * n + j] = best
  for i in 0 ..< n * n: storeI64Le(output, 8 * i, result[i])
  int64(bytes)
