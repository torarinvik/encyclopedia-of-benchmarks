proc board_path*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "board_path".} =
  if input.isNil or length != csize_t(2): return -1
  let startValue = input[0]
  let endValue = input[1]
  if startValue < 0 or endValue < 0 or startValue > 30 or endValue > 30 or startValue > endValue: return -1
  let start = int(startValue)
  let ending = int(endValue)
  var ways: array[31, int64]
  ways[ending] = 1
  if ending > start:
    for i in countdown(ending - 1, start):
      for die in 1..6:
        if i + die <= ending: ways[i] += ways[i + die]
  ways[start]
