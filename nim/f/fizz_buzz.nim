proc tokenLength(value: int64): csize_t =
  if value mod 15 == 0: return 8
  if value mod 3 == 0 or value mod 5 == 0: return 4
  if value >= 100: return 3
  if value >= 10: return 2
  1

proc appendNumber(valueValue: int64, output: ptr UncheckedArray[uint8], positionValue: csize_t): csize_t =
  var value = valueValue
  var position = positionValue
  if value >= 100:
    output[position] = uint8(48 + value div 100)
    inc position
    value = value mod 100
    output[position] = uint8(48 + value div 10)
    inc position
    output[position] = uint8(48 + value mod 10)
    inc position
  elif value >= 10:
    output[position] = uint8(48 + value div 10)
    inc position
    output[position] = uint8(48 + value mod 10)
    inc position
  else:
    output[position] = uint8(48 + value)
    inc position
  position

proc fizz_buzz*(value: int64, output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "fizz_buzz".} =
  if value < 1 or value > 512: return -1
  var width = csize_t(0)
  for current in 1'i64 .. value: width += tokenLength(current) + 1
  if output.isNil or outputCapacity < width: return -2
  var position = csize_t(0)
  for current in 1'i64 .. value:
    if current mod 15 == 0:
      for byte in [uint8('F'), uint8('i'), uint8('z'), uint8('z'), uint8('B'), uint8('u'), uint8('z'), uint8('z')]:
        output[position] = byte
        inc position
    elif current mod 3 == 0:
      for byte in [uint8('F'), uint8('i'), uint8('z'), uint8('z')]:
        output[position] = byte
        inc position
    elif current mod 5 == 0:
      for byte in [uint8('B'), uint8('u'), uint8('z'), uint8('z')]:
        output[position] = byte
        inc position
    else:
      position = appendNumber(current, output, position)
    output[position] = uint8(' ')
    inc position
  int64(position)
