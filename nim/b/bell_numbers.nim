## Return the exact Bell number for indices that fit in signed 64-bit output.
proc bell_numbers*(n: int64): int64 {.cdecl, exportc: "bell_numbers".} =
  if n < 0 or n > 25: return -1
  if n == 0: return 1

  var row: array[26, int64]
  row[0] = 1
  for current in 1 ..< int(n):
    let previousFirst = row[0]
    let previousLast = row[current - 1]
    row[0] = previousLast
    var previousOld = previousFirst
    for column in 1 .. current:
      let oldValue = if column < current: row[column] else: 0'i64
      row[column] = row[column - 1] + previousOld
      previousOld = oldValue
  row[int(n) - 1]
