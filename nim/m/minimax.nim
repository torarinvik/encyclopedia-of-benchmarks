const
  MaxLeaves = 32
  MaxInputLength = 2 + MaxLeaves
  InvalidResult = -2_147_483_649'i64
  I32Min = -2_147_483_648'i64
  I32Max = 2_147_483_647'i64

proc evaluate(values: ptr UncheckedArray[int64], index, depth, height: int, maximizing: bool): int64 =
  if depth == height: return values[2 + index]
  let left = evaluate(values, index * 2, depth + 1, height, not maximizing)
  let right = evaluate(values, index * 2 + 1, depth + 1, height, not maximizing)
  if maximizing: max(left, right) else: min(left, right)

proc minimax*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "minimax".} =
  if values == nil or length < 2 or length > MaxInputLength: return InvalidResult
  let leafCount = values[0]
  let firstTurnIsMax = values[1]
  if leafCount < 1 or leafCount > MaxLeaves or (leafCount and (leafCount - 1)) != 0: return InvalidResult
  if (firstTurnIsMax != 0 and firstTurnIsMax != 1) or length != csize_t(2 + leafCount): return InvalidResult
  for leaf in 0 ..< int(leafCount):
    if values[2 + leaf] < I32Min or values[2 + leaf] > I32Max: return InvalidResult
  var height = 0
  var width = int(leafCount)
  while width > 1:
    width = width div 2
    inc height
  evaluate(values, 0, 0, height, firstTurnIsMax == 1)
