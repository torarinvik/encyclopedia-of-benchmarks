const
  MaxWords = 257
  MaxPayload = 255'i64
  MaxOutput = 257

proc consistent_overhead_byte_stuffing*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "consistent_overhead_byte_stuffing".} =
  if input.isNil or length < 1 or length > csize_t(MaxWords): return -1
  let payloadValue = input[0]
  if payloadValue < 0 or payloadValue > MaxPayload: return -1
  let payloadLength = int(payloadValue)
  if length != csize_t(payloadLength + 1): return -1
  for index in 0 ..< payloadLength:
    if input[index + 1] < 0 or input[index + 1] > 255: return -1

  var staged: array[MaxOutput, uint8]
  var written = 1
  var codePosition = 0
  var code = 1'u16
  var omittedTerminalCode = false
  for index in 0 ..< payloadLength:
    let byte = uint8(input[index + 1])
    if byte == 0:
      staged[codePosition] = uint8(code)
      codePosition = written
      inc written
      code = 1
    else:
      staged[written] = byte
      inc written
      inc code
      if code == 255:
        staged[codePosition] = 255
        if index + 1 == payloadLength:
          omittedTerminalCode = true
          break
        codePosition = written
        inc written
        code = 1
  if not omittedTerminalCode: staged[codePosition] = uint8(code)
  if output.isNil or capacity < csize_t(written): return -2
  for index in 0 ..< written: output[index] = staged[index]
  int64(written)
