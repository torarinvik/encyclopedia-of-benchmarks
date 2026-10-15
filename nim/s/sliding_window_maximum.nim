const MaxLength = 1024

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8: output[offset + b] = uint8((bits shr (b * 8)) and 255)

proc sliding_window_maximum*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "sliding_window_maximum".} =
  if input == nil or length < 2 or length > csize_t(MaxLength + 2): return -1
  let nValue = input[0]
  let kValue = input[1]
  if nValue < 0 or nValue > MaxLength.int64 or kValue < 1 or kValue > MaxLength.int64: return -1
  let n = int(nValue)
  let k = int(kValue)
  if int(length) != n + 2: return -1
  for i in 0 ..< n:
    if input[2 + i] < int64(low(int32)) or input[2 + i] > int64(high(int32)): return -1
  let windows = if n >= k: n - k + 1 else: 0
  if capacity < csize_t(windows * 8) or (windows > 0 and output == nil): return -2
  var deque: array[MaxLength, int]
  var head = 0
  var tail = 0
  var outIndex = 0
  for i in 0 ..< n:
    while head < tail and deque[head] + k <= i: inc head
    while head < tail and input[2 + deque[tail - 1]] < input[2 + i]: dec tail
    deque[tail] = i
    inc tail
    if i + 1 >= k:
      storeI64Le(output, outIndex * 8, input[2 + deque[head]])
      inc outIndex
  int64(windows)
