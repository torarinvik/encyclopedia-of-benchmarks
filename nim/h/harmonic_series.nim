proc appendDecimal(output: ptr UncheckedArray[uint8], positionInput: int, valueInput: int): int =
  var value = valueInput
  var digits: array[4, uint8]
  var count = 0
  while true:
    digits[count] = uint8(value mod 10)
    inc count
    value = value div 10
    if value == 0: break
  var position = positionInput
  while count > 0:
    dec count
    output[position] = uint8('0') + digits[count]
    inc position
  position

proc harmonic_series*(n: int64, output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "harmonic_series".} =
  if n < -512 or n > 512: return -1
  if n <= 0: return 0
  var needed = 2
  for term in 2 .. int(n):
    var value = term
    var digits = 0
    while true:
      inc digits
      value = value div 10
      if value == 0: break
    needed += digits + 3
  if output == nil or capacity < csize_t(needed): return -2
  var position = 0
  output[position] = uint8('1'); inc position
  output[position] = uint8('\n'); inc position
  for term in 2 .. int(n):
    output[position] = uint8('1'); inc position
    output[position] = uint8('/'); inc position
    position = appendDecimal(output, position, term)
    output[position] = uint8('\n'); inc position
  int64(position)
