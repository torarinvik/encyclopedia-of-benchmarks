const MinOrder = 4
const MaxOrder = 64
const FnvOffset = 0xcbf29ce484222325'u64
const FnvPrime = 0x100000001b3'u64

proc hashByte(hashValue: var uint64, value: uint8) =
  hashValue = (hashValue xor uint64(value)) *% FnvPrime

proc hashI32(hashValue: var uint64, value: int32) =
  let bits = cast[uint32](value)
  for shift in countup(0, 24, 8):
    hashByte(hashValue, uint8(bits shr shift))

proc magic_square_doubly_even_complement*(n: int64): int64 {.cdecl, exportc: "magic_square_doubly_even_complement".} =
  if n < MinOrder or n > MaxOrder or n mod 4 != 0: return -1
  let order = int(n)
  let ceiling = order * order + 1
  var hashValue = FnvOffset
  hashByte(hashValue, uint8(order))

  for row in 0 ..< order:
    for column in 0 ..< order:
      var value = row * order + column + 1
      let localRow = row mod 4
      let localColumn = column mod 4
      if localRow == localColumn or localRow + localColumn == 3:
        value = ceiling - value
      hashI32(hashValue, int32(value))
  int64(hashValue and 0x7fff_ffff_ffff_ffff'u64)
