const MaxN = 128

proc nussinov*(values: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "nussinov".} =
  if values == nil or length != 1: return -1
  let nValue = values[0]
  if nValue < 1 or nValue > MaxN: return -1
  let n = int(nValue)
  var bases: array[MaxN, int64]
  var table: array[MaxN, array[MaxN, int64]]
  for i in 0 ..< n: bases[i] = int64((i + 1) mod 4)

  var i = n - 1
  while i >= 0:
    var j = i + 1
    while j < n:
      var score = table[i][j - 1]
      if i + 1 < n:
        score = max(score, table[i + 1][j])
        var inside = table[i + 1][j - 1]
        if i < j - 1 and bases[i] + bases[j] == 3: inc inside
        score = max(score, inside)
      var k = i + 1
      while k < j:
        score = max(score, table[i][k] + table[k + 1][j])
        inc k
      table[i][j] = score
      inc j
    dec i

  var checksum = 0'i64
  for row in 0 ..< n:
    for col in row ..< n: checksum += table[row][col]
  checksum
