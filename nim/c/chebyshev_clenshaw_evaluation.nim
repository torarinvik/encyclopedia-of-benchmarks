const
  Modulus = 998244353'i64
  MaxDegree = 16
  MaxParseableLength = 21

proc reduceField(value: int64): int64 =
  let reduced = value mod Modulus
  if reduced < 0: reduced + Modulus else: reduced

proc chebyshev_clenshaw_evaluation*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "chebyshev_clenshaw_evaluation".} =
  if input == nil or length < 3 or length > csize_t(MaxParseableLength): return -1
  let degreeValue = input[0]
  if degreeValue < 0 or degreeValue > int64(MaxDegree): return -1
  let degree = int(degreeValue)
  if int(length) != degree + 3: return -1
  let x = input[1]
  if x < 0 or x >= Modulus: return -1
  for i in 0 .. degree:
    if input[2 + i] < 0 or input[2 + i] >= Modulus: return -1

  let twiceX = (2 * x) mod Modulus
  var nextOne = 0'i64
  var nextTwo = 0'i64
  var k = degree
  while k > 0:
    let current = reduceField(input[2 + k] + twiceX * nextOne - nextTwo)
    nextTwo = nextOne
    nextOne = current
    dec k
  reduceField(input[2] + x * nextOne - nextTwo)
