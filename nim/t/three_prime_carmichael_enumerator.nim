const
  MaxLimit = 61
  MaxTriples = 69

proc tpcIsPrime(value: int64): bool =
  if value < 2:
    return false
  if value mod 2 == 0:
    return value == 2
  var divisor = 3'i64
  while divisor <= value div divisor:
    if value mod divisor == 0:
      return false
    divisor += 2
  true

proc tpcPutU32(output: ptr UncheckedArray[uint8], offset: int, value: uint32) =
  for byte in 0 ..< 4:
    output[offset + byte] = uint8((value shr (byte * 8)) and 0xff'u32)

proc three_prime_carmichael_enumerator*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "three_prime_carmichael_enumerator".} =
  if input.isNil or length != csize_t(1):
    return -1
  let limit = input[0]
  if limit < 2 or limit > int64(MaxLimit):
    return -1

  var triples: array[MaxTriples * 3, uint32]
  var tripleCount = 0
  for p1 in 2'i64 .. limit:
    if not tpcIsPrime(p1):
      continue
    for h3 in 2'i64 ..< p1:
      let g = h3 + p1
      for d in 1'i64 ..< g:
        if (g * (p1 - 1)) mod d != 0:
          continue
        let negativeSquareResidue = (h3 - (p1 * p1) mod h3) mod h3
        if negativeSquareResidue != d mod h3:
          continue
        let p2 = 1 + (p1 - 1) * g div d
        if p2 <= p1 or not tpcIsPrime(p2):
          continue
        let p3 = 1 + (p1 * p2) div h3
        if p3 <= p2 or not tpcIsPrime(p3):
          continue
        if (p2 * p3) mod (p1 - 1) != 1:
          continue
        triples[tripleCount * 3] = uint32(p1)
        triples[tripleCount * 3 + 1] = uint32(p2)
        triples[tripleCount * 3 + 2] = uint32(p3)
        inc tripleCount

  let required = 4 + tripleCount * 12
  if output.isNil or capacity < csize_t(required):
    return -2
  tpcPutU32(output, 0, uint32(tripleCount))
  for record in 0 ..< tripleCount:
    tpcPutU32(output, 4 + record * 12, triples[record * 3])
    tpcPutU32(output, 8 + record * 12, triples[record * 3 + 1])
    tpcPutU32(output, 12 + record * 12, triples[record * 3 + 2])
  int64(required)
