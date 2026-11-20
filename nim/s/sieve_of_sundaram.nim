## Count primes through limit with Sundaram's index sieve.
proc sieve_of_sundaram*(limit: int64): int64 {.cdecl, exportc: "sieve_of_sundaram".} =
  if limit < 0 or limit > 4096: return -1
  if limit < 2: return 0

  let maxIndex = int((limit - 1) div 2)
  var composite: array[2048, bool]
  var i = 1
  while 2 * i * (i + 1) <= maxIndex:
    var j = i
    while true:
      let index = i + j + 2 * i * j
      if index > maxIndex: break
      composite[index] = true
      inc j
    inc i

  var count = 1'i64
  var index = 1
  while index <= maxIndex:
    if not composite[index]: inc count
    inc index
  count
