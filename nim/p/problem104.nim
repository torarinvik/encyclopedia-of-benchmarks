const MaxFibonacciIndex = 1_000_002
const MaxLimbs = 24_000
const LimbBase = 1_000_000_000'u64

proc isPandigital1To9(value: uint32): bool =
  var remaining = value
  var mask = 0'u16
  for _ in 0 ..< 9:
    let digit = remaining mod 10
    let bit = 1'u16 shl int(digit)
    if digit == 0 or (mask and bit) != 0: return false
    mask = mask or bit
    remaining = remaining div 10
  remaining == 0 and mask == 0x3fe'u16

proc powerOfTen(exponent: uint32): uint32 =
  var value = 1'u32
  for _ in 0 ..< int(exponent): value *= 10
  value

proc leadingNineDigits(limbs: ptr UncheckedArray[uint32], length: int): uint32 =
  let top = limbs[length - 1]
  var width = 0'u32
  var temp = top
  while temp > 0:
    inc width
    temp = temp div 10
  if width >= 9 or length == 1: return top
  let fill = 9'u32 - width
  let nextPrefix = limbs[length - 2] div powerOfTen(width)
  top * powerOfTen(fill) + nextPrefix

proc problem104*(placeholder: int64): int64 {.cdecl, exportc: "problem104".} =
  if placeholder != 0: return -1
  var firstBuffer: array[MaxLimbs, uint32]
  var secondBuffer: array[MaxLimbs, uint32]
  firstBuffer[0] = 1
  secondBuffer[0] = 1
  var previous = cast[ptr UncheckedArray[uint32]](addr firstBuffer[0])
  var current = cast[ptr UncheckedArray[uint32]](addr secondBuffer[0])
  var previousLength = 1
  var currentLength = 1

  for index in 3 .. MaxFibonacciIndex:
    let sumLength = max(previousLength, currentLength)
    var carry = 0'u64
    for limb in 0 ..< sumLength:
      let left = if limb < previousLength: uint64(previous[limb]) else: 0'u64
      let right = if limb < currentLength: uint64(current[limb]) else: 0'u64
      let sum = left + right + carry
      previous[limb] = uint32(sum mod LimbBase)
      carry = sum div LimbBase
    var nextLength = sumLength
    if carry != 0:
      if nextLength == MaxLimbs: return -1
      previous[nextLength] = uint32(carry)
      inc nextLength
    let temporary = previous
    previous = current
    current = temporary
    previousLength = currentLength
    currentLength = nextLength
    if isPandigital1To9(current[0]) and isPandigital1To9(leadingNineDigits(current, currentLength)):
      return int64(index)
  -1
