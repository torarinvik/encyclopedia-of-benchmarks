const MaxOrder = 31
const FnvOffset = 0xcbf29ce484222325'u64
const FnvPrime = 0x100000001b3'u64

proc hashByte(hashValue: var uint64, value: uint8) =
  hashValue = (hashValue xor uint64(value)) *% FnvPrime

proc hashI32(hashValue: var uint64, value: int32) =
  let bits = cast[uint32](value)
  for shift in countup(0, 24, 8):
    hashByte(hashValue, uint8(bits shr shift))

proc magic_square*(n: int64): int64 {.cdecl, exportc: "magic_square".} =
  if n < 1 or n > MaxOrder or n mod 2 == 0: return -1
  let order = int(n)
  var square: array[961, int32]
  var row = order div 2
  var column = order - 1
  square[row * MaxOrder + column] = 1
  for value in 2 .. order * order:
    let nextRow = (row - 1 + order) mod order
    let nextColumn = (column + 1) mod order
    if square[nextRow * MaxOrder + nextColumn] == 0:
      row = nextRow
      column = nextColumn
    else:
      column = (column - 1 + order) mod order
    square[row * MaxOrder + column] = int32(value)

  var hashValue = FnvOffset
  hashByte(hashValue, uint8(order))
  for r in 0 ..< order:
    for c in 0 ..< order:
      hashI32(hashValue, square[r * MaxOrder + c])
  int64(hashValue and 0x7fff_ffff_ffff_ffff'u64)
