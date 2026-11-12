const
  N = 24
  MaxRepetitions = N * N div 4
  InputMax = N + 1
  ZMax = 2 * N + 1

proc zValues(text: array[ZMax, int64], length: int, z: var array[ZMax, int]) =
  for i in 0 ..< length: z[i] = 0
  var left = 0
  var right = 0
  var hasBox = false
  for i in 1 ..< length:
    if hasBox and i <= right:
      z[i] = min(right - i + 1, z[i - left])
    while i + z[i] < length and text[z[i]] == text[i + z[i]]:
      inc z[i]
    if not hasBox or i + z[i] - 1 > right:
      left = i
      right = i + z[i] - 1
      hasBox = true

proc zAt(z: array[ZMax, int], length, index: int): int =
  if index < length: z[index] else: 0

proc divide(symbols: array[N, int64], offset, length: int,
            marked: var array[N * (N + 1), bool]) =
  if length <= 1: return
  let leftSize = length div 2
  let rightSize = length - leftSize
  let middle = offset + leftSize
  var buffer: array[ZMax, int64]
  var z: array[ZMax, int]
  var before, after: array[N, int]

  divide(symbols, offset, leftSize, marked)
  divide(symbols, middle, rightSize, marked)

  for i in 0 ..< leftSize: buffer[i] = symbols[middle - 1 - i]
  zValues(buffer, leftSize, z)
  for center in 0 ..< leftSize:
    before[center] = zAt(z, leftSize, leftSize - center)

  var used = 0
  for i in 0 ..< rightSize:
    buffer[used] = symbols[middle + i]
    inc used
  buffer[used] = -1
  inc used
  for i in 0 ..< leftSize:
    buffer[used] = symbols[offset + i]
    inc used
  zValues(buffer, used, z)
  for center in 0 ..< leftSize:
    after[center] = zAt(z, used, rightSize + 1 + center)

  for i in 0 ..< leftSize: buffer[i] = symbols[middle - 1 - i]
  used = leftSize
  buffer[used] = -1
  inc used
  for i in 0 ..< rightSize:
    buffer[used] = symbols[offset + length - 1 - i]
    inc used
  zValues(buffer, used, z)
  for d in 0 ..< rightSize:
    before[leftSize + d] = zAt(z, used, leftSize + 1 + rightSize - 1 - d)

  for i in 0 ..< rightSize: buffer[i] = symbols[middle + i]
  zValues(buffer, rightSize, z)
  for d in 0 ..< rightSize:
    after[leftSize + d] = zAt(z, rightSize, d + 1)

  for center in 0 ..< length:
    let leftBiased = center < leftSize
    let half = if leftBiased: leftSize - center else: center - leftSize + 1
    if before[center] + after[center] < half: continue
    let low = max(1, half - after[center])
    let high = min(half, before[center])
    if low > high: continue
    for firstHalf in low .. high:
      if leftBiased and firstHalf == half: continue
      let start = if leftBiased: center - firstHalf else: center - half - firstHalf + 1
      marked[(offset + start) * (N + 1) + half] = true

proc storeLe(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc main_lorentz_tandem_repetitions*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl,
    exportc: "main_lorentz_tandem_repetitions".} =
  if input.isNil or length < 1 or length > csize_t(InputMax): return -1
  let nRaw = input[0]
  if nRaw < 0 or nRaw > N.int64 or int(length) != int(nRaw) + 1: return -1
  let n = int(nRaw)
  var symbols: array[N, int64]
  for i in 0 ..< n:
    symbols[i] = input[i + 1]
    if symbols[i] < 0 or symbols[i] > 255: return -1

  var marked: array[N * (N + 1), bool]
  divide(symbols, 0, n, marked)
  var codes: array[MaxRepetitions, int64]
  var count = 0
  for start in 0 ..< n:
    for half in 1 .. n div 2:
      if start + 2 * half <= n and marked[start * (N + 1) + half]:
        codes[count] = int64(start * 32 + half)
        inc count
  let required = 8 * (count + 1)
  if output.isNil or capacity < csize_t(required): return -2
  storeLe(output, 0, int64(count))
  for i in 0 ..< count: storeLe(output, 8 * (i + 1), codes[i])
  int64(required)
