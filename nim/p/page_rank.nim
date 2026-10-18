import math

const MaxNodes = 4

proc finite(value: float64): bool = classify(value) notin {fcNan, fcInf, fcNegInf}

proc page_rank*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "page_rank".} =
  if input == nil or inputLength < 6 or inputLength > 18: return -1
  for i in 0 ..< 2:
    if not finite(input[i]) or input[i] != floor(input[i]): return -1
  if input[0] < 2 or input[0] > 4 or input[1] < 0 or input[1] > 8: return -1
  let nodes = int(input[0])
  let iterations = int(input[1])
  if inputLength != csize_t(2 + nodes * nodes): return -1
  var matrix: array[16, uint8]
  var degrees: array[MaxNodes, int]
  for row in 0 ..< nodes:
    for column in 0 ..< nodes:
      let value = input[2 + row * nodes + column]
      if not finite(value) or (value != 0 and value != 1) or (row == column and value != 0): return -1
      matrix[row * nodes + column] = uint8(value)
      degrees[row] += int(matrix[row * nodes + column])
  var ranks: array[MaxNodes, float64]
  for i in 0 ..< nodes: ranks[i] = 1.0 / float64(nodes)
  for iteration in 0 ..< iterations:
    var danglingSum = 0.0
    for source in 0 ..< nodes:
      if degrees[source] == 0: danglingSum += ranks[source]
    let danglingShare = (danglingSum * 0.5) / float64(nodes)
    let baseline = 0.5 / float64(nodes) + danglingShare
    var next: array[MaxNodes, float64]
    for target in 0 ..< nodes:
      var incoming = 0.0
      for source in 0 ..< nodes:
        if matrix[source * nodes + target] == 1:
          incoming += ranks[source] / float64(degrees[source])
      next[target] = baseline + incoming * 0.5
    ranks = next
  if output == nil or capacity < csize_t(nodes): return -2
  for i in 0 ..< nodes: output[i] = ranks[i]
  int64(nodes)
