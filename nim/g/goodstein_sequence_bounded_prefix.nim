const MaxInputWords = 3
const MaxTransitions = 16'i64

proc smallPower(base, exponent: int64): int64 =
  result = 1
  for _ in 0'i64 ..< exponent:
    result *= base

proc rebaseHereditary(value, base, raisedBase: int64): int64 =
  if value == 0: return 0
  var place = 1'i64
  var exponent = 0'i64
  while place <= value:
    let digit = (value div place) mod base
    if digit != 0:
      result += digit * smallPower(raisedBase,
        rebaseHereditary(exponent, base, raisedBase))
    place *= base
    inc exponent

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc goodstein_sequence_bounded_prefix*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "goodstein_sequence_bounded_prefix".} =
  if input == nil or length < 1 or length > MaxInputWords or length != 2: return -1
  let start = input[0]
  let transitions = input[1]
  if start < 0 or start > 4 or transitions < 0 or transitions > MaxTransitions: return -1

  var terms: array[17, int64]
  var count = 1
  terms[0] = start
  var current = start
  var base = 2'i64
  for _ in 0'i64 ..< transitions:
    if current == 0: break
    current = rebaseHereditary(current, base, base + 1) - 1
    inc base
    terms[count] = current
    inc count

  let outputBytes = (count + 1) * 8
  if output == nil or capacity < csize_t(outputBytes): return -2
  storeI64Le(output, 0, int64(count))
  for index in 0 ..< count:
    storeI64Le(output, (index + 1) * 8, terms[index])
  int64(outputBytes)
