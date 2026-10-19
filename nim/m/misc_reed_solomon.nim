## Derived from the Reed-Solomon program by Simon Rockliff, 26 June 1991.
## See benchmarks/m/misc_reed_solomon/LICENSE.txt for the complete permission notice.
type
  I64Input = ptr UncheckedArray[int64]
  ByteOutput = ptr UncheckedArray[uint8]
  I32Array = ptr UncheckedArray[int32]

const
  MessageBytes = 188
  ParityBytes = 16
  CodewordBytes = 204
  FullBytes = 255

proc makeTables(alpha, indexOf: I32Array) =
  let polynomial = [1'i32, 0, 1, 1, 1, 0, 0, 0]
  for i in 0 ..< 256: indexOf[i] = -1
  var mask = 1'i32
  var alpha8 = 0'i32
  for i in 0 ..< 8:
    alpha[i] = mask
    indexOf[int(alpha[i])] = int32(i)
    if polynomial[i] != 0: alpha8 = alpha8 xor mask
    mask = mask shl 1
  alpha[8] = alpha8
  indexOf[int(alpha8)] = 8
  mask = mask shr 1
  for i in 9 ..< FullBytes:
    if alpha[i - 1] >= mask:
      alpha[i] = alpha8 xor ((alpha[i - 1] xor mask) shl 1)
    else:
      alpha[i] = alpha[i - 1] shl 1
    indexOf[int(alpha[i])] = int32(i)
  indexOf[0] = -1

proc makeGenerator(alpha, indexOf, generator: I32Array) =
  generator[0] = 2
  generator[1] = 1
  for root in 2 .. ParityBytes:
    generator[root] = 1
    var index = root - 1
    while index > 0:
      if generator[index] != 0:
        generator[index] = generator[index - 1] xor
          alpha[int((indexOf[int(generator[index])] + int32(root)) mod int32(FullBytes))]
      else:
        generator[index] = generator[index - 1]
      dec index
    generator[0] = alpha[int((indexOf[int(generator[0])] + int32(root)) mod int32(FullBytes))]
  for index in 0 .. ParityBytes: generator[index] = indexOf[int(generator[index])]

proc encode(values: I64Input, alpha, indexOf, generator, codeword: I32Array) =
  var data: array[239, int32]
  var parity: array[ParityBytes, int32]
  for index in 0 ..< MessageBytes: data[51 + index] = int32(values[index])
  for dataIndex in countdown(238, 0):
    let feedback = indexOf[int(data[dataIndex] xor parity[15])]
    if feedback != -1:
      for parityIndex in countdown(15, 1):
        if generator[parityIndex] != -1:
          parity[parityIndex] = parity[parityIndex - 1] xor
            alpha[int((generator[parityIndex] + feedback) mod int32(FullBytes))]
        else:
          parity[parityIndex] = parity[parityIndex - 1]
      parity[0] = alpha[int((generator[0] + feedback) mod int32(FullBytes))]
    else:
      for parityIndex in countdown(15, 1): parity[parityIndex] = parity[parityIndex - 1]
      parity[0] = 0
  for index in 0 ..< MessageBytes: codeword[index] = int32(values[index])
  for index in 0 ..< ParityBytes: codeword[MessageBytes + index] = parity[index]

proc multiply(left, right: int32, alpha, indexOf: I32Array): int32 =
  if left == 0 or right == 0: return 0
  var exponent = indexOf[int(left)] + indexOf[int(right)]
  if exponent >= FullBytes: exponent -= int32(FullBytes)
  alpha[int(exponent)]

proc divide(left, right: int32, alpha, indexOf: I32Array): int32 =
  if left == 0: return 0
  var exponent = indexOf[int(left)] - indexOf[int(right)]
  if exponent < 0: exponent += int32(FullBytes)
  alpha[int(exponent)]

proc correctOne(codeword: I32Array, expectedPosition: int, alpha, indexOf: I32Array): bool =
  var syndrome1 = 0'i32
  var syndrome2 = 0'i32
  for fullPosition in 0 ..< FullBytes:
    var symbol = 0'i32
    if fullPosition < ParityBytes:
      symbol = codeword[MessageBytes + fullPosition]
    elif fullPosition >= 67:
      symbol = codeword[fullPosition - 67]
    syndrome1 = syndrome1 xor multiply(symbol, alpha[fullPosition mod FullBytes], alpha, indexOf)
    syndrome2 = syndrome2 xor multiply(symbol, alpha[(2 * fullPosition) mod FullBytes], alpha, indexOf)
  if syndrome1 == 0 and syndrome2 == 0: return true
  if syndrome1 == 0: return false
  let location = divide(syndrome2, syndrome1, alpha, indexOf)
  var fullPosition = -1
  for index in 0 ..< FullBytes:
    if alpha[index] == location:
      fullPosition = index
      break
  if fullPosition < 0: return false
  var transmittedPosition: int
  if fullPosition < ParityBytes: transmittedPosition = MessageBytes + fullPosition
  elif fullPosition >= 67: transmittedPosition = fullPosition - 67
  else: return false
  if transmittedPosition != expectedPosition: return false
  let magnitude = divide(syndrome1, alpha[fullPosition], alpha, indexOf)
  codeword[transmittedPosition] = codeword[transmittedPosition] xor magnitude
  true

proc misc_reed_solomon*(values: I64Input, length: csize_t, output: ByteOutput,
                        outputCapacity: csize_t): int64 {.cdecl, exportc: "misc_reed_solomon".} =
  if values.isNil or (length != 189 and length != 191): return -1
  for index in 0 ..< MessageBytes:
    if values[index] < 0 or values[index] > 255: return -1
  let errorCount = values[MessageBytes]
  if (errorCount == 0 and length != 189) or (errorCount == 1 and length != 191) or
      (errorCount != 0 and errorCount != 1): return -1
  var errorPosition = -1
  if errorCount == 1:
    if values[189] < 0 or values[189] >= CodewordBytes or values[190] < 0 or values[190] > 255: return -1
    errorPosition = int(values[189])
  if output.isNil or outputCapacity < CodewordBytes: return -2

  var alpha: array[FullBytes, int32]
  var indexOf: array[256, int32]
  var generator: array[ParityBytes + 1, int32]
  var staged: array[CodewordBytes, int32]
  let alphaPtr = cast[I32Array](addr alpha[0])
  let indexPtr = cast[I32Array](addr indexOf[0])
  let generatorPtr = cast[I32Array](addr generator[0])
  let stagedPtr = cast[I32Array](addr staged[0])
  makeTables(alphaPtr, indexPtr)
  makeGenerator(alphaPtr, indexPtr, generatorPtr)
  encode(values, alphaPtr, indexPtr, generatorPtr, stagedPtr)
  if errorCount == 1: staged[int(errorPosition)] = int32(values[190])
  if not correctOne(stagedPtr, errorPosition, alphaPtr, indexPtr): return -1
  for index in 0 ..< CodewordBytes: output[index] = uint8(staged[index])
  int64(CodewordBytes)
