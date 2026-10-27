const MaxN = 8
const MaxInput = 65
const Inf = 1_000_000'i64

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc apsp_min_plus_repeated_squaring*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "apsp_min_plus_repeated_squaring".} =
  if input.isNil or length < 2 or length > MaxInput: return -1
  let n0 = input[0]
  if n0 < 1 or n0 > MaxN: return -1
  let n = int(n0)
  if int(length) != 1 + n * n: return -1
  var current, next: array[64, int64]
  for i in 0 ..< n:
    for j in 0 ..< n:
      let value = input[1 + i * n + j]
      if (i == j and value != 0) or
          (i != j and value != Inf and (value < 1 or value > 1000)): return -1
      current[i * n + j] = value
  var edgeBound = 1
  while edgeBound < n - 1:
    for i in 0 ..< n:
      for j in 0 ..< n:
        var best = Inf
        for k in 0 ..< n:
          let left = current[i * n + k]
          let right = current[k * n + j]
          if left != Inf and right != Inf and left + right < best: best = left + right
        next[i * n + j] = best
    for index in 0 ..< n * n: current[index] = next[index]
    edgeBound *= 2
  let bytes = 8 * n * n
  if output.isNil or int(capacity) < bytes: return -2
  for index in 0 ..< n * n: storeI64Le(output, 8 * index, current[index])
  int64(bytes)
