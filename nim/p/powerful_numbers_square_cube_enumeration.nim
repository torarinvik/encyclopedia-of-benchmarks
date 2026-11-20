const MaxInputWords = 2
const MaxLimit = 100'i64

proc isSquarefree(value: int64): bool =
  var divisor = 2'i64
  while divisor <= value div divisor:
    if value mod (divisor * divisor) == 0: return false
    inc divisor
  true

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc powerful_numbers_square_cube_enumeration*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "powerful_numbers_square_cube_enumeration".} =
  if input == nil or length < 1 or length > MaxInputWords or length != 1: return -1
  let limit = input[0]
  if limit < 1 or limit > MaxLimit: return -1

  var values: array[14, int64]
  var count = 0
  var b = 1'i64
  while b * b * b <= limit:
    if isSquarefree(b):
      let cube = b * b * b
      var a = 1'i64
      while a * a * cube <= limit:
        values[count] = a * a * cube
        inc count
        inc a
    inc b

  for index in 1 ..< count:
    let value = values[index]
    var position = index
    while position > 0 and values[position - 1] > value:
      values[position] = values[position - 1]
      dec position
    values[position] = value

  let outputBytes = (count + 1) * 8
  if output == nil or capacity < csize_t(outputBytes): return -2
  storeI64Le(output, 0, int64(count))
  for index in 0 ..< count:
    storeI64Le(output, (index + 1) * 8, values[index])
  int64(outputBytes)
