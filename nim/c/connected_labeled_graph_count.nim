const
  MaxN = 512
  Modulus = 998244353'i64

proc modPow(baseValue: int64, exponentValue: int): int64 =
  var resultValue = 1'i64
  var base = baseValue
  var exponent = exponentValue
  while exponent > 0:
    if (exponent and 1) != 0: resultValue = resultValue * base mod Modulus
    base = base * base mod Modulus
    exponent = exponent shr 1
  resultValue

proc solve(n: int): int64 =
  var factorial, inverseFactorial, allGraphs, connected: array[MaxN + 1, int64]
  factorial[0] = 1
  for i in 1 .. n:
    factorial[i] = factorial[i - 1] * int64(i) mod Modulus
  inverseFactorial[n] = modPow(factorial[n], 998244351)
  for i in countdown(n, 1):
    inverseFactorial[i - 1] = inverseFactorial[i] * int64(i) mod Modulus

  allGraphs[0] = 1
  var edgeChoices = 1'i64
  for size in 1 .. n:
    allGraphs[size] = allGraphs[size - 1] * edgeChoices mod Modulus
    edgeChoices = edgeChoices * 2 mod Modulus
  connected[1] = 1
  if n >= 2:
    for size in 2 .. n:
      var disconnected = 0'i64
      for componentSize in 1 ..< size:
        var choose = factorial[size - 1] * inverseFactorial[componentSize - 1] mod Modulus
        choose = choose * inverseFactorial[size - componentSize] mod Modulus
        var term = choose * connected[componentSize] mod Modulus
        term = term * allGraphs[size - componentSize] mod Modulus
        disconnected = (disconnected + term) mod Modulus
      connected[size] = (allGraphs[size] - disconnected + Modulus) mod Modulus
  connected[n]

proc connected_labeled_graph_count*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "connected_labeled_graph_count".} =
  if input.isNil or length != csize_t(1): return -1
  if input[0] < 1 or input[0] > int64(MaxN): return -1
  solve(int(input[0]))
