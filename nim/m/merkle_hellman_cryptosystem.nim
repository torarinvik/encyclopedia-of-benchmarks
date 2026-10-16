proc gcdU64(aValue, bValue: uint64): uint64 =
  var a = aValue
  var b = bValue
  while b != 0'u64:
    let remainder = a mod b
    a = b
    b = remainder
  a

proc addMod(a, b, modulus: uint64): uint64 =
  if a >= modulus - b: a - (modulus - b) else: a + b

proc mulMod(aValue, bValue, modulus: uint64): uint64 =
  var a = aValue mod modulus
  var b = bValue
  var result = 0'u64
  while b != 0'u64:
    if (b and 1'u64) != 0'u64: result = addMod(result, a, modulus)
    b = b shr 1
    if b != 0'u64: a = addMod(a, a, modulus)
  result

proc inverseMod(value, modulus: uint64): uint64 =
  var oldR = modulus
  var r = value mod modulus
  var oldT = 0'u64
  var t = 1'u64
  while r != 0'u64:
    let quotient = oldR div r
    let nextR = oldR mod r
    let product = mulMod(quotient mod modulus, t, modulus)
    let nextT = if oldT >= product: oldT - product else: modulus - (product - oldT)
    oldR = r
    r = nextR
    oldT = t
    t = nextT
  oldT

proc putI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc merkle_hellman_cryptosystem*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "merkle_hellman_cryptosystem".} =
  if input.isNil or length < 12 or length > 43: return -1
  if input[0] < 0 or input[0] > 127 or input[10] < 1 or input[10] > 32: return -1
  let drawCount = int(input[10])
  if int(length) != 11 + drawCount: return -1

  var easy: array[8, uint64]
  var total = 1'u64 shl 32
  for index in 0 ..< 8:
    if input[1 + index] < 0 or input[1 + index] > 4_294_967_295'i64: return -1
    easy[index] = total + uint64(input[1 + index])
    total += easy[index]
  if input[9] < 0 or input[9] > 4_294_967_295'i64: return -1
  let modulus = total + uint64(input[9])
  for index in 0 ..< drawCount:
    let drawValue = input[11 + index]
    if drawValue < 0 or uint64(drawValue) > modulus: return -1
    let divisor = gcdU64(uint64(drawValue), modulus)
    if index + 1 < drawCount and divisor == 1'u64: return -1
    if index + 1 == drawCount and divisor != 1'u64: return -1
  if output.isNil or outputCapacity < 17: return -2

  let multiplier = uint64(input[10 + drawCount])
  var hard: array[8, uint64]
  for index in 0 ..< 8: hard[index] = mulMod(multiplier, easy[index], modulus)
  let message = uint64(input[0])
  var ciphertext = 0'u64
  for bitIndex in countdown(7, 0):
    if ((message shr bitIndex) and 1'u64) != 0'u64:
      ciphertext += hard[7 - bitIndex]

  let inverse = inverseMod(multiplier, modulus)
  var residue = mulMod(inverse, ciphertext mod modulus, modulus)
  var decoded = 0'u8
  for index in 0 ..< 8:
    let weight = easy[7 - index]
    if residue >= weight:
      residue -= weight
      decoded = decoded or (1'u8 shl index)
  if residue != 0'u64 or uint64(decoded) != message: return -1
  putI64Le(output, 0, int64(ciphertext))
  putI64Le(output, 8, 1)
  output[16] = decoded
  17
