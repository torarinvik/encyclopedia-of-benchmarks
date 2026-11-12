const MaxInput = 259
const MaxOutput = 2040
const MaxN = 128
const MaxM = 128

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc min_plus_convolution_convex_convex*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "min_plus_convolution_convex_convex".} =
  if input == nil or length < 4 or length > csize_t(MaxInput): return -1
  let n0 = input[0]; let m0 = input[1]
  if n0 < 1 or n0 > 128 or m0 < 1 or m0 > 128: return -1
  let n = int(n0); let m = int(m0)
  if int(length) != 2 + n + m: return -1
  var a: array[MaxN, int64]
  var b: array[MaxM, int64]
  for i in 0 ..< n + m:
    let value = input[2 + i]
    if value < 0 or value > 1_000_000_000: return -1
    if i < n: a[i] = value else: b[i - n] = value
  for i in 0 ..< max(0, n - 2):
    if a[i + 1] - a[i] > a[i + 2] - a[i + 1]: return -1
  for i in 0 ..< max(0, m - 2):
    if b[i + 1] - b[i] > b[i + 2] - b[i + 1]: return -1

  let count = n + m - 1
  let bytes = 8 * count
  if bytes > MaxOutput: return -1
  if output == nil or capacity < csize_t(bytes): return -2

  var result: array[MaxN + MaxM - 1, int64]
  result[0] = a[0] + b[0]
  var ai = 0
  var bi = 0
  var out = 1
  while ai + 1 < n or bi + 1 < m:
    var slope: int64
    if bi + 1 == m or (ai + 1 < n and a[ai + 1] - a[ai] <= b[bi + 1] - b[bi]):
      slope = a[ai + 1] - a[ai]
      inc ai
    else:
      slope = b[bi + 1] - b[bi]
      inc bi
    result[out] = result[out - 1] + slope
    inc out
  for i in 0 ..< count: storeI64Le(output, 8 * i, result[i])
  int64(bytes)
