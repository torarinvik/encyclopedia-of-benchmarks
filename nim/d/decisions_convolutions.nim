const MaxDecisions = 64
const MaxCriteria = 16
const MaxValue = 100000'i64

proc decisions_convolutions*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "decisions_convolutions".} =
  if input == nil or length < 3: return -1
  let operation = input[0]
  let nArg = input[1]
  let mArg = input[2]
  if (operation != 0 and operation != 1) or nArg < 1 or nArg > MaxDecisions or mArg < 1 or mArg > MaxCriteria: return -1
  let n = int(nArg)
  let m = int(mArg)
  if length != csize_t(3 + m + n * m): return -1
  for j in 0 ..< m:
    if input[3 + j] < -MaxValue or input[3 + j] > MaxValue: return -1
  for i in 0 ..< n * m:
    if input[3 + m + i] < -MaxValue or input[3 + m + i] > MaxValue: return -1
  var bestScore = 0'i64
  var bestIndex = 0
  for i in 0 ..< n:
    var score = 0'i64
    for j in 0 ..< m:
      let product = input[3 + m + i * m + j] * input[3 + j]
      if operation == 0: score += product
      elif j == 0 or product < score: score = product
    if i == 0 or score > bestScore:
      bestScore = score
      bestIndex = i
  int64(bestIndex)
