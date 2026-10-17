const MaxN = 64
const MaxParseableInputLength = MaxN + 4
const MaxOutputBytes = MaxN * 8
const MaxPlaces = 1_000_000'i64
const I32MinValue = -2147483648'i64
const I32MaxValue = 2147483647'i64

proc writeI64Le(buffer: var array[MaxOutputBytes, uint8], offset: int, value: int64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    buffer[offset + byte] = uint8(bits and 255)
    bits = bits shr 8

proc rotate_to_the_right*(input: ptr UncheckedArray[int64], length: csize_t,
                          output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "rotate_to_the_right".} =
  if input.isNil or length < 3 or length > MaxParseableInputLength.csize_t: return -1
  let nValue = input[0]
  let places = input[1]
  if nValue < 1 or nValue > MaxN.int64 or places < -MaxPlaces or places > MaxPlaces: return -1
  let n = nValue.int
  if length != (n + 2).csize_t: return -1
  for index in 0 ..< n:
    let value = input[2 + index]
    if value < I32MinValue or value > I32MaxValue: return -1

  let remainder = places mod nValue
  let shift = (if remainder < 0: remainder + nValue else: remainder).int
  let outputBytes = n * 8
  if output.isNil or outputCapacity < outputBytes.csize_t: return -2

  var encoded: array[MaxOutputBytes, uint8]
  for index in 0 ..< n:
    let source = (index + n - shift) mod n
    writeI64Le(encoded, index * 8, input[2 + source])
  for index in 0 ..< outputBytes:
    output[index] = encoded[index]
  outputBytes.int64
