const MaxParseableInputLength = 292
const MaxMessageBytes = 32

proc lsbImageSteganography*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "lsb_image_steganography".} =
  if input.isNil or length < 3 or length > csize_t(MaxParseableInputLength): return -1
  if input[0] < 1 or input[0] > 16 or input[1] < 1 or input[1] > 16 or input[2] < 0 or input[2] > MaxMessageBytes: return -1
  let rows = int(input[0]); let columns = int(input[1]); let messageLength = int(input[2])
  let pixelCount = rows * columns
  if messageLength * 8 > pixelCount or int(length) != 3 + pixelCount + messageLength: return -1
  for i in 0 ..< pixelCount:
    if input[3 + i] < 0 or input[3 + i] > 254: return -1
  for i in 0 ..< messageLength:
    if input[3 + pixelCount + i] < 0 or input[3 + pixelCount + i] > 127: return -1
  if output.isNil or outputCapacity < csize_t(pixelCount): return -2
  for i in 0 ..< pixelCount: output[i] = uint8(input[3 + i])
  var bitIndex = 0
  for i in 0 ..< messageLength:
    let byte = uint8(input[3 + pixelCount + i])
    for shift in countdown(7, 0):
      let bit = (byte shr shift) and 1
      let pixel = output[bitIndex]
      output[bitIndex] = pixel + ((pixel and 1) xor bit)
      inc bitIndex
  int64(pixelCount)
