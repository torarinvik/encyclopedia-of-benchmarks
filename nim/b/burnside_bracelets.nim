const MaxN = 10
const MaxInputValues = 3
const OutputBytes = 8

proc cycleCount(n, shift: int, reflection: bool): int =
  var seen: array[MaxN, bool]
  var cycles = 0
  for start in 0 ..< n:
    if seen[start]: continue
    inc cycles
    var position = start
    while not seen[position]:
      seen[position] = true
      if reflection: position = (shift + n - position) mod n
      else: position = (position + shift) mod n
  cycles

proc fixedColorings(n, shift: int, reflection: bool, colors: int64): int64 =
  let cycles = cycleCount(n, shift, reflection)
  result = 1
  for _ in 0 ..< cycles:
    result *= colors

proc storeI64Le(output: ptr UncheckedArray[uint8], value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< OutputBytes:
    output[byte] = uint8((bits shr (8 * byte)) and 0xff'u64)

proc burnside_bracelets*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "burnside_bracelets".} =
  if input.isNil or length < csize_t(1) or length > csize_t(MaxInputValues): return -1
  if length != csize_t(2): return -1
  let nValue = input[0]
  let colors = input[1]
  if nValue < 1 or nValue > MaxN.int64 or colors < 0 or colors > 3: return -1
  let n = int(nValue)

  var fixedSum = 0'i64
  for shift in 0 ..< n:
    fixedSum += fixedColorings(n, shift, false, colors)
    fixedSum += fixedColorings(n, shift, true, colors)
  let answer = fixedSum div int64(2 * n)
  if output.isNil or capacity < csize_t(OutputBytes): return -2
  storeI64Le(output, answer)
  OutputBytes.int64
