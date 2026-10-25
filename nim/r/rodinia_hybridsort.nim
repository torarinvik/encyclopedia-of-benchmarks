## Rodinia histogram bucket partition followed by a merge sort inside each bucket.
proc bucket(value, minimum, span: float32): int =
  var index = int(((value - minimum) / span) * 1024.0'f32)
  if index < 0: index = 0
  if index >= 1024: index = 1023
  index

proc mergeSort(items: var openArray[int64], scratch: var openArray[int64], start, count: int) =
  var width = 1
  while width < count:
    var left = 0
    while left < count:
      let middle = min(left + width, count)
      let right = min(left + 2 * width, count)
      var a = left; var b = middle; var outIndex = left
      while a < middle and b < right:
        if items[start + a] <= items[start + b]:
          scratch[outIndex] = items[start + a]; inc a
        else:
          scratch[outIndex] = items[start + b]; inc b
        inc outIndex
      while a < middle: scratch[outIndex] = items[start + a]; inc a; inc outIndex
      while b < right: scratch[outIndex] = items[start + b]; inc b; inc outIndex
      left += 2 * width
    for i in 0 ..< count: items[start + i] = scratch[i]
    width *= 2

proc putI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8: output[offset + b] = uint8((bits shr (8 * b)) and 255'u64)

proc rodinia_hybridsort*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "rodinia_hybridsort".} =
  if input.isNil or length < 3 or length > 65: return -1
  if input[0] < 2 or input[0] > 64 or length != csize_t(input[0] + 1): return -1
  let count = int(input[0])
  var items: array[64, int64]
  var scratch: array[64, int64]
  var minRaw = int64.high; var maxRaw = int64.low
  for i in 0 ..< count:
    let raw = input[1 + i]
    if raw < 0 or raw > 1_000_000 or raw mod 1000 != 0: return -1
    items[i] = raw; minRaw = min(minRaw, raw); maxRaw = max(maxRaw, raw)
  if minRaw == maxRaw: return -1
  let outputBytes = count * 8
  if output.isNil or capacity < csize_t(outputBytes): return -2
  let minimum = float32(minRaw) / 1_000_000.0'f32
  let maximum = float32(maxRaw) / 1_000_000.0'f32
  let span = maximum - minimum
  var histogram: array[1024, int]
  var offsets: array[1025, int]
  var next: array[1024, int]
  var scattered: array[64, int64]
  for i in 0 ..< count:
    let value = float32(items[i]) / 1_000_000.0'f32
    inc histogram[bucket(value, minimum, span)]
  for b in 0 ..< 1024:
    offsets[b + 1] = offsets[b] + histogram[b]
    next[b] = offsets[b]
  for i in 0 ..< count:
    let value = float32(items[i]) / 1_000_000.0'f32
    let b = bucket(value, minimum, span)
    scattered[next[b]] = items[i]
    inc next[b]
  for b in 0 ..< 1024:
    let start = offsets[b]; let size = offsets[b + 1] - start
    if size > 1: mergeSort(scattered, scratch, start, size)
  for i in 0 ..< count: putI64(output, i * 8, scattered[i])
  int64(outputBytes)
