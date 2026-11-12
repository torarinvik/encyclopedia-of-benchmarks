const
  MaxN = 1_000_000_000_000'i64
  MaxRoot = 1_000_000

proc integerSqrt(value: int64): int64 =
  var low = 1'i64
  var high = int64(MaxRoot)
  while low < high:
    let middle = low + (high - low + 1) div 2
    if middle <= value div middle: low = middle
    else: high = middle - 1
  low

proc counting_squarefrees*(n: int64): int64 {.cdecl, exportc: "counting_squarefrees".} =
  if n < 1 or n > MaxN: return -1
  let limit = int(integerSqrt(n))
  var mobius: array[MaxRoot + 1, uint8]
  var composite: array[MaxRoot + 1, bool]
  for value in 1..limit: mobius[value] = 1

  for prime in 2..limit:
    if composite[prime]: continue
    if prime <= limit div prime:
      var markMultiple = prime * prime
      while markMultiple <= limit:
        composite[markMultiple] = true
        markMultiple += prime
    var factorMultiple = prime
    while factorMultiple <= limit:
      if mobius[factorMultiple] == 1: mobius[factorMultiple] = 2
      elif mobius[factorMultiple] == 2: mobius[factorMultiple] = 1
      factorMultiple += prime
    if prime <= limit div prime:
      let square = prime * prime
      var squareMultiple = square
      while squareMultiple <= limit:
        mobius[squareMultiple] = 0
        squareMultiple += square

  var count = 0'i64
  for divisor in 1..limit:
    let d = int64(divisor)
    let quotient = n div (d * d)
    if mobius[divisor] == 1: count += quotient
    elif mobius[divisor] == 2: count -= quotient
  count
