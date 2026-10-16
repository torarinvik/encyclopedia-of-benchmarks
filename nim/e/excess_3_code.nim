proc excess_3_code*(value: int64, output: ptr UncheckedArray[uint8],
                    outputCapacity: csize_t): int64
    {.cdecl, exportc: "excess_3_code".} =
  var number = if value < 0: 0'u64 else: uint64(value)
  var digits: array[19, uint8]
  var count = 0
  while number > 0:
    digits[count] = uint8(number mod 10)
    inc count
    number = number div 10
  if count == 0:
    digits[0] = 0
    count = 1
  let outputLength = 2 + 4 * count
  if output == nil or outputCapacity < csize_t(outputLength): return -2
  output[0] = uint8('0')
  output[1] = uint8('b')
  var position = 2
  while count > 0:
    dec count
    let nibble = int(digits[count]) + 3
    for bit in countdown(3, 0):
      output[position] = if (nibble and (1 shl bit)) != 0: uint8('1') else: uint8('0')
      inc position
  int64(outputLength)
