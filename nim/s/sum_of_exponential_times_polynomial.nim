## Finite geometric power sum by binary composition of moment blocks.
const Modulus = 998244353'i64
const MaxDegree = 32

proc sepmShift(source: openArray[int64], shift: uint64, degree: int,
               choose: openArray[int64]): array[MaxDegree + 1, int64] =
  var powers: array[MaxDegree + 1, int64]
  result[0] = 0
  powers[0] = 1
  let reducedShift = int64(shift mod uint64(Modulus))
  for i in 1..degree:
    powers[i] = powers[i - 1] * reducedShift mod Modulus
  for d in 0..degree:
    var total = 0'i64
    for k in 0..d:
      let term = choose[d * (MaxDegree + 1) + k] * powers[d - k] mod Modulus
      total = (total + term * source[k]) mod Modulus
    result[d] = total

proc sum_of_exponential_times_polynomial*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "sum_of_exponential_times_polynomial".} =
  if input == nil or length != 3: return -1
  let r = input[0]
  let degreeValue = input[1]
  let nValue = input[2]
  if r < 0 or r >= Modulus or degreeValue < 0 or degreeValue > MaxDegree.int64 or
      nValue < 0 or nValue > 1_000_000_000_000_000_000'i64: return -1
  let degree = int(degreeValue)
  var choose: array[(MaxDegree + 1) * (MaxDegree + 1), int64]
  choose[0] = 1
  for d in 1..degree:
    choose[d * (MaxDegree + 1)] = 1
    choose[d * (MaxDegree + 1) + d] = 1
    for k in 1..<d:
      choose[d * (MaxDegree + 1) + k] =
        (choose[(d - 1) * (MaxDegree + 1) + k - 1] + choose[(d - 1) * (MaxDegree + 1) + k]) mod Modulus

  var accumulated: array[MaxDegree + 1, int64]
  var blockMoments: array[MaxDegree + 1, int64]
  blockMoments[0] = 1
  var accumulatedPower = 1'i64
  var blockPower = r
  var accumulatedLength = 0'u64
  var blockLength = 1'u64
  var remaining = uint64(nValue)
  while remaining > 0:
    if (remaining and 1'u64) != 0:
      let shifted = sepmShift(blockMoments, accumulatedLength, degree, choose)
      for d in 0..degree:
        accumulated[d] = (accumulated[d] + accumulatedPower * shifted[d]) mod Modulus
      accumulatedPower = accumulatedPower * blockPower mod Modulus
      accumulatedLength += blockLength
    let shiftedBlock = sepmShift(blockMoments, blockLength, degree, choose)
    for d in 0..degree:
      blockMoments[d] = (blockMoments[d] + blockPower * shiftedBlock[d]) mod Modulus
    blockPower = blockPower * blockPower mod Modulus
    blockLength = blockLength shl 1
    remaining = remaining shr 1
  accumulated[degree]
