proc questionFunction(n: int64): int64 =
  var term = 1'i64
  var total = 0'i64
  for exponent in 0..10:
    if exponent mod 2 == 0: total += term
    else: total -= term
    term *= n
  total

proc problem101*(order: int64): int64 {.cdecl, exportc: "problem101".} =
  if order > 10: return -1
  if order <= 0: return 0
  var data: array[10, int64]
  for i in 0..<int(order): data[i] = questionFunction(int64(i + 1))
  var totalFit = 0'i64
  for k in 1..int(order):
    var row: array[10, int64]
    var differences: array[10, int64]
    for i in 0..<k: row[i] = data[i]
    differences[0] = row[0]
    for level in 1..<k:
      for i in 0..<(k - level): row[i] = row[i + 1] - row[i]
      differences[level] = row[0]
    var x = 1'i64
    while true:
      var prediction = 0'i64
      var choose = 1'i64
      for j in 0..<k:
        prediction += differences[j] * choose
        if j + 1 < k: choose = choose * (x - 1 - int64(j)) div int64(j + 1)
      if prediction != questionFunction(x):
        totalFit += prediction
        break
      inc x
  totalFit
