## Count values through limit with exactly ten valid arithmetic-progression solutions.
const MaxLimit = 1_000_000'i64

proc problem135*(limit: int64): int64 {.cdecl, exportc: "problem135".} =
  if limit > MaxLimit: return -1
  if limit < 0: return 0
  var frequency: array[1_000_001, uint8]
  var firstTerm = 1'i64
  while firstTerm <= limit:
    var n = firstTerm
    while n <= limit:
      var commonDifference = firstTerm + n div firstTerm
      if commonDifference mod 4 == 0:
        commonDifference = commonDifference div 4
        if firstTerm > commonDifference and firstTerm < 4 * commonDifference:
          let index = int(n)
          if frequency[index] < 11'u8: inc frequency[index]
      n += firstTerm
    inc firstTerm
  var count = 0'i64
  for n in 1'i64 .. limit:
    if frequency[int(n)] == 10'u8: inc count
  count
