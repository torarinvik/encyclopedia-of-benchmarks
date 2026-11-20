const
  MaxParseableLength = 6
  MaxDenominations = 4'i64
  MaxDenomination = 16'i64
  DistanceInf = 1_000_000'i64

proc fnaGcd(leftValue, rightValue: int64): int64 =
  var left = leftValue
  var right = rightValue
  while right != 0:
    let remainder = left mod right
    left = right
    right = remainder
  left

proc fnaApery(input: ptr UncheckedArray[int64], count, modulus: int): int64 =
  var distance: array[16, int64]
  var settled: array[16, bool]
  for residue in 0 ..< modulus: distance[residue] = DistanceInf
  distance[0] = 0
  for _ in 0 ..< modulus:
    var source = -1
    var best = DistanceInf
    for residue in 0 ..< modulus:
      if not settled[residue] and distance[residue] < best:
        source = residue
        best = distance[residue]
    if source < 0: return -1
    settled[source] = true
    for index in 0 ..< count:
      let coin = input[index + 1]
      let target = (source + int(coin)) mod modulus
      let candidate = best + coin
      if candidate < distance[target]: distance[target] = candidate
  var maximum = 0'i64
  for residue in 0 ..< modulus:
    if distance[residue] > maximum: maximum = distance[residue]
  maximum - int64(modulus)

proc solve(input: ptr UncheckedArray[int64], length: int): int64 =
  if length < 1 or length > MaxParseableLength: return -1
  let countValue = input[0]
  if countValue < 2 or countValue > MaxDenominations or length != int(countValue + 1): return -1
  let count = int(countValue)
  var common = 0'i64
  var minimum = MaxDenomination + 1
  for index in 0 ..< count:
    let coin = input[index + 1]
    if coin < 2 or coin > MaxDenomination: return -1
    for previous in 0 ..< index:
      if coin == input[previous + 1]: return -1
    common = fnaGcd(common, coin)
    if coin < minimum: minimum = coin
  if common != 1: return -1
  fnaApery(input, count, int(minimum))

proc frobenius_number_apery*(input: ptr UncheckedArray[int64],
                             length: csize_t): int64
    {.cdecl, exportc: "frobenius_number_apery".} =
  if input.isNil or length < 1 or length > csize_t(MaxParseableLength): return -1
  solve(input, int(length))
