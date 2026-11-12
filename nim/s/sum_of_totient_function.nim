const
  MaxN = 1_000_000_000'i64
  BaseLimit = 100_000
  MaxCache = 10_002
  Modulus = 998_244_353'i64

proc triangularMod(n: int64): int64 =
  var left = n
  var right = n + 1
  if left mod 2 == 0: left = left div 2
  else: right = right div 2
  (left mod Modulus) * (right mod Modulus) mod Modulus

proc summatoryPhi(value, totalN: int64, prefix: openArray[int64],
    memo: var array[MaxCache, int64], visited: var array[MaxCache, bool]): int64 =
  if value <= int64(BaseLimit): return prefix[int(value)]
  let cacheIndex = int(totalN div value)
  if visited[cacheIndex]: return memo[cacheIndex]
  var answer = triangularMod(value)
  var left = 2'i64
  while left <= value:
    let quotient = value div left
    let right = value div quotient
    let blockSize = right - left + 1
    let subSum = summatoryPhi(quotient, totalN, prefix, memo, visited)
    let contribution = (blockSize mod Modulus) * subSum mod Modulus
    answer = (answer - contribution + Modulus) mod Modulus
    left = right + 1
  visited[cacheIndex] = true
  memo[cacheIndex] = answer
  answer

proc sum_of_totient_function*(n: int64): int64 {.cdecl, exportc: "sum_of_totient_function".} =
  if n < 1 or n > MaxN: return -1
  var prefix: array[BaseLimit + 1, int64]
  let sieveLimit = min(int(n), BaseLimit)
  for value in 0..sieveLimit: prefix[value] = int64(value)
  for prime in 2..sieveLimit:
    if prefix[prime] != int64(prime): continue
    var multiple = prime
    while multiple <= sieveLimit:
      prefix[multiple] -= prefix[multiple] div int64(prime)
      multiple += prime
  var running = 0'i64
  for value in 1..sieveLimit:
    running = (running + prefix[value]) mod Modulus
    prefix[value] = running
  if n <= int64(BaseLimit): return prefix[int(n)]

  var memo: array[MaxCache, int64]
  var visited: array[MaxCache, bool]
  summatoryPhi(n, n, prefix, memo, visited)
