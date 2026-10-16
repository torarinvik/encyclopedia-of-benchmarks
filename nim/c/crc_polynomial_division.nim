type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]

proc crc_polynomial_division*(input: I64Input, length: csize_t, output: U8Output, capacity: csize_t): int64
    {.cdecl, exportc: "crc_polynomial_division".} =
  if input == nil or length < 3 or length > csize_t(3 + 79 + 16): return -1
  let operation = input[0]
  let rawMessageLength = input[1]
  let rawPolynomialLength = input[2]
  if operation < 0 or operation > 1 or rawMessageLength < 1 or
      (operation == 0 and rawMessageLength > 64) or (operation == 1 and rawMessageLength > 79) or
      rawPolynomialLength < 2 or rawPolynomialLength > 16: return -1
  let messageLength = int(rawMessageLength)
  let polynomialLength = int(rawPolynomialLength)
  if length != csize_t(3 + messageLength + polynomialLength): return -1

  var message: array[79, uint8]
  var polynomial: array[16, uint8]
  var dividend: array[79, uint8]
  var remainder: array[16, uint8]
  for i in 0..<messageLength:
    let bit = input[3 + i]
    if bit < 0 or bit > 1: return -1
    message[i] = uint8(bit)
  for i in 0..<polynomialLength:
    let bit = input[3 + messageLength + i]
    if bit < 0 or bit > 1: return -1
    polynomial[i] = uint8(bit)
  if polynomial[0] != 1 or polynomial[polynomialLength - 1] != 1: return -1

  var dividendLength = messageLength
  for i in 0..<messageLength: dividend[i] = message[i]
  if operation == 0:
    for _ in 0..<(polynomialLength - 1):
      dividend[dividendLength] = 0
      inc dividendLength
  var remainderLength = 0
  var cursor = 0
  while cursor < dividendLength:
    while remainderLength < polynomialLength and cursor < dividendLength:
      remainder[remainderLength] = dividend[cursor]
      inc remainderLength
      inc cursor
    if remainderLength == polynomialLength:
      if remainder[0] == 1:
        for i in 0..<polynomialLength: remainder[i] = remainder[i] xor polynomial[i]
      var leadingZeroes = 0
      while leadingZeroes < remainderLength and remainder[leadingZeroes] == 0: inc leadingZeroes
      for i in leadingZeroes..<remainderLength: remainder[i - leadingZeroes] = remainder[i]
      remainderLength -= leadingZeroes

  let degree = polynomialLength - 1
  let outputLength = if operation == 0: messageLength + degree else: 1
  if output == nil or capacity < csize_t(outputLength): return -2
  if operation == 0:
    for i in 0..<messageLength: output[i] = message[i]
    let leadingZeroes = degree - remainderLength
    for i in 0..<leadingZeroes: output[messageLength + i] = 0
    for i in 0..<remainderLength: output[messageLength + leadingZeroes + i] = remainder[i]
  else:
    var nonzero = 0'u8
    for i in 0..<remainderLength: nonzero = nonzero or remainder[i]
    output[0] = uint8(nonzero != 0)
  int64(outputLength)
