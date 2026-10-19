## Source-ordered double-precision matrix multiplication from Stanford RealMM.
const RowSize = 40
const CellCount = RowSize * RowSize
const MaxPasses = 10
const MaxOutputBytes = 140

proc roundedMicroUnits(bits: uint64): uint64 =
  let exponent = int((bits shr 52) and 0x7ff'u64)
  if exponent == 0: return 0
  let significand = (bits and 0x000f_ffff_ffff_ffff'u64) or (1'u64 shl 52)
  let shift = 1075 - exponent
  if shift >= 74: return 0
  let lowProduct = (significand and 0xffff_ffff'u64) * 1_000_000'u64
  let highProduct = (significand shr 32) * 1_000_000'u64
  let middle = (lowProduct shr 32) + (highProduct and 0xffff_ffff'u64)
  let limb0 = lowProduct and 0xffff_ffff'u64
  let limb1 = middle and 0xffff_ffff'u64
  let limb2 = (highProduct shr 32) + (middle shr 32)
  var quotient: uint64
  var halfBit: uint64
  var lowerNonzero: bool
  if shift < 64:
    let part = shift - 32
    quotient = (limb1 shr part) or (limb2 shl (32 - part))
    halfBit = (limb1 shr (part - 1)) and 1'u64
    lowerNonzero = limb0 != 0 or (limb1 and ((1'u64 shl (part - 1)) - 1'u64)) != 0
  elif shift == 64:
    quotient = limb2
    halfBit = limb1 shr 31
    lowerNonzero = limb0 != 0 or (limb1 and 0x7fff_ffff'u64) != 0
  else:
    let part = shift - 64
    quotient = limb2 shr part
    halfBit = (limb2 shr (part - 1)) and 1'u64
    lowerNonzero = limb0 != 0 or limb1 != 0 or (limb2 and ((1'u64 shl (part - 1)) - 1'u64)) != 0
  if halfBit != 0 and (lowerNonzero or (quotient and 1'u64) != 0): inc quotient
  quotient

proc appendInteger(buffer: var array[MaxOutputBytes, uint8], used: var int, value: uint64) =
  var remaining = value
  var reversed: array[20, uint8]
  var count = 0
  while true:
    reversed[count] = uint8(48'u64 + remaining mod 10'u64)
    inc count
    remaining = remaining div 10'u64
    if remaining == 0: break
  while count > 0:
    dec count
    buffer[used] = reversed[count]
    inc used

proc appendFixed(buffer: var array[MaxOutputBytes, uint8], used: var int, value: float64) =
  let bits = cast[uint64](value)
  if (bits shr 63) != 0:
    buffer[used] = uint8(ord('-'))
    inc used
  let scaled = roundedMicroUnits(bits and 0x7fff_ffff_ffff_ffff'u64)
  appendInteger(buffer, used, scaled div 1_000_000'u64)
  buffer[used] = uint8(ord('.')); inc used
  var fraction = scaled mod 1_000_000'u64
  var place = 100_000'u64
  while place > 0:
    buffer[used] = uint8(48'u64 + fraction div place); inc used
    fraction = fraction mod place
    place = place div 10'u64

proc stanford_realmm*(passCount: int64, output: ptr UncheckedArray[uint8],
                      outputCapacity: csize_t): int64 {.cdecl, exportc: "stanford_realmm".} =
  if passCount < 1 or passCount > MaxPasses: return -1
  if output.isNil: return -2

  var a: array[CellCount, float64]
  var b: array[CellCount, float64]
  var product: array[CellCount, float64]
  var staged: array[MaxOutputBytes, uint8]
  var used = 0
  for pass in 0 ..< int(passCount):
    var seed = 74755'i64
    for index in 0 ..< CellCount:
      seed = (seed * 1309 + 13849) and 65535
      let temp = seed
      let residue = temp - (temp div 120) * 120 - 60
      a[index] = float64(residue) / 3.0
    for index in 0 ..< CellCount:
      seed = (seed * 1309 + 13849) and 65535
      let temp = seed
      let residue = temp - (temp div 120) * 120 - 60
      b[index] = float64(residue) / 3.0

    for row in 0 ..< RowSize:
      for column in 0 ..< RowSize:
        var sum = 0.0
        for inner in 0 ..< RowSize:
          sum = sum + a[row * RowSize + inner] * b[inner * RowSize + column]
        product[row * RowSize + column] = sum
    appendFixed(staged, used, product[pass * RowSize + pass])
    staged[used] = uint8(ord('\n'))
    inc used

  if outputCapacity < csize_t(used): return -2
  for index in 0 ..< used: output[index] = staged[index]
  int64(used)
