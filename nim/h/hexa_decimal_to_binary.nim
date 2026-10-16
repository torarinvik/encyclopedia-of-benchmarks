proc hexDigit(code: int64): int =
  if code >= ord('0') and code <= ord('9'): return int(code - ord('0'))
  if code >= ord('A') and code <= ord('F'): return int(code - ord('A') + 10)
  if code >= ord('a') and code <= ord('f'): return int(code - ord('a') + 10)
  -1

proc hexa_decimal_to_binary*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "hexa_decimal_to_binary".} =
  if input.isNil or length == 0 or length > 65: return -1
  var firstDigit = 0
  var negative = false
  if input[0] == ord('-'): negative = true; firstDigit = 1
  elif input[0] == ord('+'): firstDigit = 1
  if firstDigit == int(length): return -1
  let limit = if negative: 2_147_483_648'u64 else: 2_147_483_647'u64
  var value: uint64 = 0
  for index in firstDigit ..< int(length):
    let digit = hexDigit(input[index])
    if digit < 0 or value > (limit - uint64(digit)) div 16: return -1
    value = value * 16 + uint64(digit)
  let bits = if negative and value != 0: uint32(4_294_967_296'u64 - value) else: uint32(value)
  var width = 0
  var remaining = bits
  while remaining != 0:
    inc width
    remaining = remaining shr 1
  if negative and value != 0: width = 32
  elif width < 8: width = 8
  var buffer: array[32, uint8]
  remaining = bits
  var position = width
  while position > 0:
    dec position
    buffer[position] = uint8(ord('0')) + uint8(remaining and 1)
    remaining = remaining shr 1
  if csize_t(width) > outputCapacity or output.isNil: return -2
  for index in 0 ..< width: output[index] = buffer[index]
  int64(width)
