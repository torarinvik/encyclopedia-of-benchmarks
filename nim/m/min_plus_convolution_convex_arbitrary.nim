const MaxInput = 67
const MaxOutput = 504

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc min_plus_convolution_convex_arbitrary*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "min_plus_convolution_convex_arbitrary".} =
  if input == nil or length < 4 or length > csize_t(MaxInput): return -1
  let n0 = input[0]; let m0 = input[1]
  if n0 < 1 or n0 > 32 or m0 < 1 or m0 > 32: return -1
  let n = int(n0); let m = int(m0)
  if int(length) != 2 + n + m: return -1
  var a: array[32, int64]
  var b: array[32, int64]
  for i in 0 ..< n + m:
    let value = input[2 + i]
    if value < 0 or value > 1_000_000_000: return -1
    if i < n: a[i] = value else: b[i - n] = value
  for i in 0 ..< max(0, n - 2):
    if a[i + 1] - a[i] > a[i + 2] - a[i + 1]: return -1
  let count = n + m - 1
  let bytes = 8 * count
  if bytes > MaxOutput: return -1
  if output == nil or int(capacity) < bytes: return -2
  var result: array[63, int64]
  var stackLeft, stackRight, stackOptLeft, stackOptRight: array[128, int]
  var top = 1
  stackLeft[0] = 0; stackRight[0] = count - 1; stackOptLeft[0] = 0; stackOptRight[0] = m - 1
  while top > 0:
    dec top
    let left = stackLeft[top]; let right = stackRight[top]
    let optLeft = stackOptLeft[top]; let optRight = stackOptRight[top]
    if left <= right:
      let mid = left + (right - left) div 2
      let low = max(optLeft, max(0, mid - (n - 1)))
      let high = min(optRight, min(m - 1, mid))
      var best = high(int64)
      var bestJ = low
      for j in low .. high:
        let candidate = a[mid - j] + b[j]
        if candidate < best: best = candidate; bestJ = j
      result[mid] = best
      if mid < right:
        stackLeft[top] = mid + 1; stackRight[top] = right
        stackOptLeft[top] = bestJ; stackOptRight[top] = optRight; inc top
      if left < mid:
        stackLeft[top] = left; stackRight[top] = mid - 1
        stackOptLeft[top] = optLeft; stackOptRight[top] = bestJ; inc top
  for i in 0 ..< count: storeI64Le(output, 8 * i, result[i])
  int64(bytes)
