proc unsignedBits(value: uint32, bits: var array[80, uint8]): int =
  var remaining = value
  result = 0
  while true:
    bits[result] = uint8(ord('0')) + uint8(remaining and 1)
    inc result
    remaining = remaining shr 1
    if remaining == 0: break
  for i in 0 ..< result div 2:
    swap(bits[i], bits[result - i - 1])

proc binary_shifts*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "binary_shifts".} =
  if values == nil or length != 3: return -1
  let operation = values[0]
  let number = values[1]
  let shift = values[2]
  if operation < 0 or operation > 2 or number < -2_147_483_647'i64 or
      number > 2_147_483_647'i64 or shift < 0 or shift > 31 or
      (operation < 2 and number < 0): return -1

  var bits: array[80, uint8]
  var resultBytes: array[82, uint8]
  var bitsLength = 0
  var resultLength = 0
  if operation == 0 or operation == 1:
    bitsLength = unsignedBits(uint32(number), bits)
    resultBytes[0] = uint8(ord('0')); resultBytes[1] = uint8(ord('b')); resultLength = 2
    if operation == 0:
      for i in 0 ..< bitsLength: resultBytes[resultLength] = bits[i]; inc resultLength
      for i in 0 ..< int(shift): resultBytes[resultLength] = uint8(ord('0')); inc resultLength
    elif int(shift) >= bitsLength:
      resultBytes[resultLength] = uint8(ord('0')); inc resultLength
    else:
      for i in 0 ..< bitsLength - int(shift): resultBytes[resultLength] = bits[i]; inc resultLength
  else:
    if number >= 0:
      bits[0] = uint8(ord('0'))
      var ordinary: array[80, uint8]
      let ordinaryLength = unsignedBits(uint32(number), ordinary)
      for i in 0 ..< ordinaryLength: bits[i + 1] = ordinary[i]
      bitsLength = ordinaryLength + 1
    else:
      let magnitude = uint32(-number)
      let magnitudeLength = unsignedBits(magnitude, bits)
      let complement = (1'u32 shl magnitudeLength) - magnitude
      var complementBits: array[40, uint8]
      let complementLength = unsignedBits(complement, complementBits)
      bits[0] = uint8(ord('1'))
      var position = 1
      for i in complementLength ..< magnitudeLength: bits[position] = uint8(ord('0')); inc position
      for i in 0 ..< complementLength: bits[position] = complementBits[i]; inc position
      bitsLength = position
    resultBytes[0] = uint8(ord('0')); resultBytes[1] = uint8(ord('b')); resultLength = 2
    let sign = bits[0]
    if int(shift) >= bitsLength:
      for i in 0 ..< bitsLength: resultBytes[resultLength] = sign; inc resultLength
    else:
      for i in 0 ..< int(shift): resultBytes[resultLength] = sign; inc resultLength
      for i in 0 ..< bitsLength - int(shift): resultBytes[resultLength] = bits[i]; inc resultLength

  if output == nil or outputCapacity < csize_t(resultLength): return -2
  for i in 0 ..< resultLength: output[i] = resultBytes[i]
  int64(resultLength)
