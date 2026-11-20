const MaxOrder = 30
const FnvOffset = 0xcbf29ce484222325'u64
const FnvPrime = 0x100000001b3'u64

proc hashByte(hashValue: var uint64, value: uint8) =
  hashValue = (hashValue xor uint64(value)) *% FnvPrime

proc hashI32(hashValue: var uint64, value: int32) =
  let bits = cast[uint32](value)
  for shift in countup(0, 24, 8):
    hashByte(hashValue, uint8(bits shr shift))

proc magic_square_singly_even_strachey*(n: int64): int64 {.cdecl, exportc: "magic_square_singly_even_strachey".} =
  if n < 6 or n > MaxOrder or n mod 4 != 2: return -1
  let order = int(n)
  let half = order div 2
  let k = half div 2
  let blockSize = half * half
  var odd: array[900, int32]
  var square: array[900, int32]

  var row = 0
  var column = half div 2
  odd[row * MaxOrder + column] = 1
  for value in 2 .. blockSize:
    let nextRow = (row - 1 + half) mod half
    let nextColumn = (column + 1) mod half
    if odd[nextRow * MaxOrder + nextColumn] == 0:
      row = nextRow
      column = nextColumn
    else:
      row = (row + 1) mod half
    odd[row * MaxOrder + column] = int32(value)

  for r in 0 ..< half:
    for c in 0 ..< half:
      let value = odd[r * MaxOrder + c]
      square[r * MaxOrder + c] = value
      square[r * MaxOrder + half + c] = value + int32(2 * blockSize)
      square[(half + r) * MaxOrder + c] = value + int32(3 * blockSize)
      square[(half + r) * MaxOrder + half + c] = value + int32(blockSize)

  for r in 0 ..< half:
    for c in 0 ..< k:
      let top = r * MaxOrder + c
      let bottom = (half + r) * MaxOrder + c
      let saved = square[top]
      square[top] = square[bottom]
      square[bottom] = saved
    for c in (half - (k - 1)) ..< half:
      let top = r * MaxOrder + half + c
      let bottom = (half + r) * MaxOrder + half + c
      let saved = square[top]
      square[top] = square[bottom]
      square[bottom] = saved

  let firstMiddleTop = k * MaxOrder
  let firstMiddleBottom = (half + k) * MaxOrder
  let savedFirst = square[firstMiddleTop]
  square[firstMiddleTop] = square[firstMiddleBottom]
  square[firstMiddleBottom] = savedFirst
  let centerTop = k * MaxOrder + k
  let centerBottom = (half + k) * MaxOrder + k
  let savedCenter = square[centerTop]
  square[centerTop] = square[centerBottom]
  square[centerBottom] = savedCenter

  var hashValue = FnvOffset
  hashByte(hashValue, uint8(order))
  for r in 0 ..< order:
    for c in 0 ..< order:
      hashI32(hashValue, square[r * MaxOrder + c])
  int64(hashValue and 0x7fff_ffff_ffff_ffff'u64)
