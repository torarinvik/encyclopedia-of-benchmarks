const MaxParseableLength = 2

proc middlePoint(first, second: int): int =
  if first == second: return -1
  let firstX = first mod 3
  let firstY = first div 3
  let secondX = second mod 3
  let secondY = second div 3
  let deltaX = secondX - firstX
  let deltaY = secondY - firstY
  if deltaX mod 2 != 0 or deltaY mod 2 != 0: return -1
  let middle = ((firstY + secondY) div 2) * 3 + (firstX + secondX) div 2
  if middle == first or middle == second: return -1
  middle

proc countFrom(last, visited, used, target: int): int64 =
  if used == target: return 1
  for next in 0 ..< 9:
    let bit = 1 shl next
    if (visited and bit) == 0:
      let middle = middlePoint(last, next)
      if middle < 0 or (visited and (1 shl middle)) != 0:
        result += countFrom(next, visited or bit, used + 1, target)

proc android_unlock_pattern_count*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "android_unlock_pattern_count".} =
  if input.isNil or length != csize_t(1): return -1
  let targetValue = input[0]
  if targetValue < 4 or targetValue > 9: return -1
  let target = int(targetValue)
  for start in 0 ..< 9:
    result += countFrom(start, 1 shl start, 1, target)
