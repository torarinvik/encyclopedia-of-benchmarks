const
  Modulus = 998_244_353'i64
  MaxN = 32
  MaxInput = 66
  MaxBlocks = 6
  MaxPowers = 7

type Polynomial = array[MaxN, int64]
type PowerTable = array[MaxPowers, Polynomial]
type BlockTable = array[MaxBlocks, Polynomial]

proc multiplyTruncated(left, right: Polynomial, n: int): Polynomial =
  var product: Polynomial
  for i in 0 ..< n:
    for j in 0 ..< (n - i):
      product[i + j] = (product[i + j] + left[i] * right[j]) mod Modulus
  product

proc storeLe(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc brent_kung_fps_composition*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "brent_kung_fps_composition".} =
  if input == nil or length < 3 or length > csize_t(MaxInput): return -1
  let nValue = input[0]
  if nValue < 1 or nValue > MaxN: return -1
  let n = int(nValue)
  if int(length) != 1 + 2 * n: return -1
  for i in 0 ..< 2 * n:
    if input[i + 1] < 0 or input[i + 1] >= Modulus: return -1
  if input[1 + n] != 0: return -1
  let bytes = 8 * n
  if output == nil or int(capacity) < bytes: return -2

  var blockSize = 1
  while blockSize * blockSize < n: inc blockSize
  let blockCount = (n + blockSize - 1) div blockSize
  var powers: PowerTable
  var blocks: BlockTable
  var inner: Polynomial
  for degree in 0 ..< n: inner[degree] = input[1 + n + degree]
  powers[0][0] = 1
  for exponent in 1 .. blockSize:
    powers[exponent] = multiplyTruncated(powers[exponent - 1], inner, n)
  for block in 0 ..< blockCount:
    for offset in 0 ..< blockSize:
      let coefficientIndex = block * blockSize + offset
      if coefficientIndex >= n: break
      let coefficient = input[1 + coefficientIndex]
      for degree in 0 ..< n:
        blocks[block][degree] =
          (blocks[block][degree] + coefficient * powers[offset][degree]) mod Modulus
  var composed = blocks[blockCount - 1]
  var block = blockCount - 1
  while block > 0:
    composed = multiplyTruncated(composed, powers[blockSize], n)
    for degree in 0 ..< n:
      composed[degree] = (composed[degree] + blocks[block - 1][degree]) mod Modulus
    dec block
  for degree in 0 ..< n: storeLe(output, 8 * degree, composed[degree])
  int64(bytes)
