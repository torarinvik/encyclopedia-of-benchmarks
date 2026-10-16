proc problem191*(days: int64): int64 {.cdecl, exportc: "problem191".} =
  if days < 0 or days > 65: return -1
  var ways: array[396, int64]
  for absent in 0..1:
    for late in 0..2: ways[absent * 3 + late] = 1
  for remaining in 1..int(days):
    for absent in 0..1:
      for late in 0..2:
        let previous = (remaining - 1) * 6
        let lateState = if late < 2: ways[previous + absent * 3 + late + 1] else: 0'i64
        let absentState = if absent == 0: ways[previous + 3] else: 0'i64
        let onTimeState = ways[previous + absent * 3]
        ways[remaining * 6 + absent * 3 + late] = lateState + absentState + onTimeState
  ways[int(days) * 6]
