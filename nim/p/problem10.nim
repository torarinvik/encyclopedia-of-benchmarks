proc problem10*(limit: int64): int64 {.cdecl, exportc: "problem10".} =
  if limit < 0 or limit > 2_000_000: return -1
  var composite: array[1_000_000, bool]
  let oddCount = int(limit div 2)
  var total = if limit > 2: 2'i64 else: 0'i64
  var prime = 3
  while prime * prime < int(limit):
    if not composite[prime div 2]:
      var index = prime * prime div 2
      while index < oddCount:
        composite[index] = true
        index += prime
    prime += 2
  for index in 1..<oddCount:
    if not composite[index]: total += int64(2 * index + 1)
  total
