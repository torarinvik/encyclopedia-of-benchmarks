const MaxN = 10000

proc minimum_steps_to_one*(n: int64): int64 {.cdecl, exportc: "minimum_steps_to_one".} =
  if n < 1 or n > MaxN: return -1
  var table: array[MaxN + 1, int64]
  for index in 0 .. int(n): table[index] = n + 1
  table[1] = 0
  var i = 1
  while i < int(n):
    let candidate = table[i] + 1
    if table[i + 1] > candidate: table[i + 1] = candidate
    if i * 2 <= int(n) and table[i * 2] > candidate: table[i * 2] = candidate
    if i * 3 <= int(n) and table[i * 3] > candidate: table[i * 3] = candidate
    inc i
  table[int(n)]
