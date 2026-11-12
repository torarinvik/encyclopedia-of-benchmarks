type
  I64Input = ptr UncheckedArray[int64]
  ByteOutput = ptr UncheckedArray[uint8]

proc nimProduct(a, b: uint64, width: int): uint64 =
  if width == 1: return a and b
  let half = width div 2
  let mask = (1'u64 shl half) - 1'u64
  let aLow = a and mask
  let aHigh = a shr half
  let bLow = b and mask
  let bHigh = b shr half
  let lowProduct = nimProduct(aLow, bLow, half)
  let highProduct = nimProduct(aHigh, bHigh, half)
  let cross = nimProduct(aLow xor aHigh, bLow xor bHigh, half) xor lowProduct xor highProduct
  let constant = 1'u64 shl (half - 1)
  let low = lowProduct xor nimProduct(highProduct, constant, half)
  let high = cross xor highProduct
  low xor (high shl half)

proc nim_product_64*(input: I64Input, length: csize_t,
                     output: ByteOutput, outputCapacity: csize_t): int64 {.cdecl, exportc: "nim_product_64".} =
  if input == nil or length != csize_t(4): return -1
  for index in 0 ..< 4:
    if input[index] < 0 or input[index] > 4_294_967_295'i64: return -1
  if output == nil or outputCapacity < csize_t(8): return -2

  let a = uint64(input[0]) or (uint64(input[1]) shl 32)
  let b = uint64(input[2]) or (uint64(input[3]) shl 32)
  let result = nimProduct(a, b, 64)
  for index in 0 ..< 8:
    output[index] = uint8((result shr (index * 8)) and 255'u64)
  8
