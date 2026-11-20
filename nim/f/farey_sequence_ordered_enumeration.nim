type I64Input = ptr UncheckedArray[int64]
type U8Output = ptr UncheckedArray[uint8]

proc fareyCount(order: int64): int64 =
  var a = 0'i64
  var b = 1'i64
  var c = 1'i64
  var d = order
  var count = 1'i64
  while true:
    inc count
    if c == d: break
    let k = (order + b) div d
    let nextC = k * c - a
    let nextD = k * d - b
    a = c
    b = d
    c = nextC
    d = nextD
  count

proc storeI64Le(output: U8Output, offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 0xff'u64)

proc farey_sequence_ordered_enumeration*(values: I64Input, length: csize_t,
    output: U8Output, outputCapacity: csize_t): int64 {.cdecl, exportc: "farey_sequence_ordered_enumeration".} =
  if values == nil or length != 1: return -1
  let order = values[0]
  if order < 1 or order > 32: return -1
  let count = fareyCount(order)
  let required = int((1 + 2 * count) * 8)
  if output == nil or outputCapacity < csize_t(required): return -2

  storeI64Le(output, 0, count)
  storeI64Le(output, 8, 0)
  storeI64Le(output, 16, 1)
  var a = 0'i64
  var b = 1'i64
  var c = 1'i64
  var d = order
  var position = 24
  while true:
    storeI64Le(output, position, c)
    storeI64Le(output, position + 8, d)
    position += 16
    if c == d: break
    let k = (order + b) div d
    let nextC = k * c - a
    let nextD = k * d - b
    a = c
    b = d
    c = nextC
    d = nextD
  int64(required)
