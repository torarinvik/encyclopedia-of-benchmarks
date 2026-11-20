const
  MaxInput = 44
  Infinity = 801'i64

proc stateIndex(color, groups: int): int = color * 9 + groups

proc paintHouseIii*(input: ptr UncheckedArray[int64],
    length: csize_t): int64 {.cdecl, exportc: "paint_house_iii".} =
  if input.isNil or length < csize_t(3) or length > csize_t(MaxInput): return -1
  let mValue = input[0]
  let nValue = input[1]
  let targetValue = input[2]
  if mValue < 1 or mValue > 8 or nValue < 1 or nValue > 4:
    return -1
  if targetValue < 1 or targetValue > mValue: return -1
  let m = int(mValue)
  let n = int(nValue)
  let target = int(targetValue)
  if length != csize_t(3 + m + m * n): return -1
  let housesAt = 3
  let costsAt = 3 + m
  for index in 0 ..< m:
    if input[housesAt + index] < 0 or input[housesAt + index] > nValue: return -1
  for index in 0 ..< m * n:
    if input[costsAt + index] < 0 or input[costsAt + index] > 100: return -1

  var previous: array[45, int64]
  var current: array[45, int64]
  for index in 0 ..< 45: previous[index] = Infinity
  let first = input[housesAt]
  for color in 1 .. n:
    if first == 0 or first == int64(color):
      previous[stateIndex(color, 1)] =
        (if first == 0: input[costsAt + color - 1] else: 0)

  for house in 1 ..< m:
    for index in 0 ..< 45: current[index] = Infinity
    let fixed = input[housesAt + house]
    for color in 1 .. n:
      if fixed != 0 and fixed != int64(color): continue
      let paintCost = if fixed == 0: input[costsAt + house * n + color - 1] else: 0
      for groups in 1 .. target:
        var best = Infinity
        for oldColor in 1 .. n:
          let decrement = if oldColor == color: 0 else: 1
          let oldGroups = groups - decrement
          if oldGroups >= 1 and previous[stateIndex(oldColor, oldGroups)] < best:
            best = previous[stateIndex(oldColor, oldGroups)]
        if best < Infinity:
          current[stateIndex(color, groups)] = best + paintCost
    for index in 0 ..< 45: previous[index] = current[index]

  var answer = Infinity
  for color in 1 .. n:
    if previous[stateIndex(color, target)] < answer:
      answer = previous[stateIndex(color, target)]
  if answer >= Infinity: return -1
  answer
