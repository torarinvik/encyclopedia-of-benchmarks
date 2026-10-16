const MaxParseableInputLength = 38

proc ipconverter*(input: ptr UncheckedArray[int64], length: csize_t,
                  output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "ipconverter".} =
  if input.isNil or length < 2 or length > MaxParseableInputLength: return -1
  let mode = input[0]
  let payloadLengthValue = input[1]
  if (mode != 0 and mode != 1) or payloadLengthValue < 0 or payloadLengthValue > 35: return -1
  let payloadLength = int(payloadLengthValue)
  if int(length) != payloadLength + 2: return -1

  var octets: array[4, int64]
  var position = 0
  if mode == 0:
    if payloadLength < 7 or payloadLength > 15: return -1
    for octet in 0 ..< 4:
      var digits = 0
      var value = 0'i64
      while position < payloadLength and input[2 + position] != 46:
        let byte = input[2 + position]
        if digits == 3 or byte < 48 or byte > 57: return -1
        value = value * 10 + byte - 48
        if value > 255: return -1
        inc digits
        inc position
      if digits == 0: return -1
      octets[octet] = value
      if octet < 3:
        if position >= payloadLength or input[2 + position] != 46: return -1
        inc position
      elif position != payloadLength:
        return -1
  else:
    if payloadLength != 35: return -1
    for octet in 0 ..< 4:
      var value = 0'i64
      for bit in 0 ..< 8:
        let byte = input[2 + position]
        inc position
        if byte != 48 and byte != 49: return -1
        value = value * 2 + byte - 48
      octets[octet] = value
      if octet < 3:
        if input[2 + position] != 46: return -1
        inc position
    if position != payloadLength: return -1

  var outputLength = 3
  if mode == 0:
    outputLength = 35
  else:
    for value in octets:
      if value >= 100: outputLength += 2
      elif value >= 10: inc outputLength
  if capacity < outputLength or output.isNil: return -2

  position = 0
  for octet in 0 ..< 4:
    if mode == 0:
      for bit in countdown(7, 0):
        output[position] = uint8(48 + ((octets[octet] shr bit) and 1))
        inc position
    else:
      var value = octets[octet]
      if value >= 100:
        output[position] = uint8(48 + value div 100)
        inc position
        value = value mod 100
      if value >= 10:
        output[position] = uint8(48 + value div 10)
        inc position
        value = value mod 10
      output[position] = uint8(48 + value)
      inc position
    if octet < 3:
      output[position] = uint8(46)
      inc position
  int64(position)
