import std/math

const MaxInputLength = 513
const MaxLength = 256

proc exactInteger(value: float64, minimum, maximum: int64): bool =
  if classify(value) in {fcNan, fcInf, fcNegInf}: return false
  if value < float64(minimum) or value > float64(maximum): return false
  float64(int64(value)) == value

proc shuffle*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "shuffle".} =
  if input == nil or inputLength < 1 or inputLength > MaxInputLength.csize_t: return -1
  if not exactInteger(input[0], 0, MaxLength): return -1
  let count = int(input[0])
  let offsetCount = max(count - 1, 0)
  if inputLength != csize_t(1 + count + offsetCount): return -1

  var items: array[MaxLength, int32]
  for index in 0 ..< count:
    let value = input[csize_t(index + 1)]
    if not exactInteger(value, int64(low(int32)), int64(high(int32))): return -1
    items[index] = int32(value)
  var offsets: array[MaxLength, int]
  for index in 0 ..< offsetCount:
    let value = input[csize_t(1 + count + index)]
    if not exactInteger(value, 0, int64(count - 1 - index)): return -1
    offsets[index] = int(value)
  for index in 0 ..< offsetCount:
    swap(items[index], items[index + offsets[index]])

  if output == nil or capacity < csize_t(count): return -2
  for index in 0 ..< count: output[index] = float64(items[index])
  int64(count)
