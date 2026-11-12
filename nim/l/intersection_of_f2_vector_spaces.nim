const MaxCases = 4
const MaxVectors = 8
const MaxBits = 30
const MaxInputValues = 1 + MaxCases * (2 + 2 * MaxVectors) + 1
const MaxOutputWords = MaxCases * (1 + MaxVectors)
const MaxVector = 0x3fff_ffff'u32

proc insertIndependent(basis: var array[MaxBits, uint32], value: uint32): bool =
  var row = value
  for bit in countdown(MaxBits - 1, 0):
    if ((row shr bit) and 1'u32) == 0: continue
    if basis[bit] != 0: row = row xor basis[bit]
    else:
      basis[bit] = row
      return true
  false

proc intersectionBasis(left: array[MaxVectors, uint32], n: int,
    right: array[MaxVectors, uint32], m: int,
    output: var array[MaxVectors, uint32]): int =
  var rightBasis, rightCoeff: array[MaxBits, uint32]
  for index in 0 ..< m:
    var row = right[index]
    var coefficients = 1'u32 shl index
    for bit in countdown(MaxBits - 1, 0):
      if ((row shr bit) and 1'u32) == 0: continue
      if rightBasis[bit] != 0:
        row = row xor rightBasis[bit]
        coefficients = coefficients xor rightCoeff[bit]
      else:
        rightBasis[bit] = row
        rightCoeff[bit] = coefficients
        break

  var quotientBasis, quotientLeftCoeff, quotientRightCoeff: array[MaxBits, uint32]
  var intersection: array[MaxVectors, uint32]
  var intersectionCount = 0
  for index in 0 ..< n:
    var row = left[index]
    var rightMask = 0'u32
    for bit in countdown(MaxBits - 1, 0):
      if ((row shr bit) and 1'u32) != 0 and rightBasis[bit] != 0:
        row = row xor rightBasis[bit]
        rightMask = rightMask xor rightCoeff[bit]
    var leftMask = 1'u32 shl index
    for bit in countdown(MaxBits - 1, 0):
      if ((row shr bit) and 1'u32) == 0: continue
      if quotientBasis[bit] != 0:
        row = row xor quotientBasis[bit]
        leftMask = leftMask xor quotientLeftCoeff[bit]
        rightMask = rightMask xor quotientRightCoeff[bit]
      else:
        quotientBasis[bit] = row
        quotientLeftCoeff[bit] = leftMask
        quotientRightCoeff[bit] = rightMask
        break
    if row == 0:
      var common = 0'u32
      for source in 0 ..< n:
        if ((leftMask shr source) and 1'u32) != 0: common = common xor left[source]
      intersection[intersectionCount] = common
      inc intersectionCount

  var rref: array[MaxBits, uint32]
  for index in 0 ..< intersectionCount:
    var row = intersection[index]
    for bit in countdown(MaxBits - 1, 0):
      if ((row shr bit) and 1'u32) == 0: continue
      if rref[bit] != 0: row = row xor rref[bit]
      else:
        rref[bit] = row
        for pivot in 0 ..< MaxBits:
          if pivot != bit and ((rref[pivot] shr bit) and 1'u32) != 0:
            rref[pivot] = rref[pivot] xor row
        break
  for bit in countdown(MaxBits - 1, 0):
    if rref[bit] != 0:
      output[result] = rref[bit]
      inc result

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc intersection_of_f2_vector_spaces*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "intersection_of_f2_vector_spaces".} =
  if input.isNil or length < 1 or length > csize_t(MaxInputValues): return -1
  let caseCountValue = input[0]
  if caseCountValue < 1 or caseCountValue > MaxCases: return -1
  let caseCount = int(caseCountValue)
  var staged: array[MaxOutputWords, int64]
  var used = 0
  var cursor = 1
  for _ in 0 ..< caseCount:
    if cursor >= int(length): return -1
    let nValue = input[cursor]
    inc cursor
    if nValue < 0 or nValue > MaxVectors: return -1
    let n = int(nValue)
    if cursor + n > int(length): return -1
    var left: array[MaxVectors, uint32]
    var leftCheck: array[MaxBits, uint32]
    for index in 0 ..< n:
      let value = input[cursor]
      inc cursor
      if value < 0 or value > int64(MaxVector): return -1
      let vector = uint32(value)
      if not insertIndependent(leftCheck, vector): return -1
      left[index] = vector
    if cursor >= int(length): return -1
    let mValue = input[cursor]
    inc cursor
    if mValue < 0 or mValue > MaxVectors: return -1
    let m = int(mValue)
    if cursor + m > int(length): return -1
    var right: array[MaxVectors, uint32]
    var rightCheck: array[MaxBits, uint32]
    for index in 0 ..< m:
      let value = input[cursor]
      inc cursor
      if value < 0 or value > int64(MaxVector): return -1
      let vector = uint32(value)
      if not insertIndependent(rightCheck, vector): return -1
      right[index] = vector
    var basis: array[MaxVectors, uint32]
    let dimension = intersectionBasis(left, n, right, m, basis)
    staged[used] = int64(dimension)
    inc used
    for index in 0 ..< dimension:
      staged[used] = int64(basis[index])
      inc used
  if cursor != int(length): return -1
  let required = 8 * used
  if output.isNil or capacity < csize_t(required): return -2
  for index in 0 ..< used: storeI64Le(output, 8 * index, staged[index])
  int64(required)
