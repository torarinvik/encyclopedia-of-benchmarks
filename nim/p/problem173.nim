const MaxTiles = 1_000_000'i64

proc problem173CeilSqrt(value: int64): int64 =
  if value <= 0: return 0
  var root = value
  var next = (root + value div root) div 2
  while next < root:
    root = next
    next = (root + value div root) div 2
  if root * root == value: root else: root + 1

proc problem173*(maxTiles: int64): int64 {.cdecl, exportc: "problem173".} =
  if maxTiles < 0 or maxTiles > MaxTiles: return -1
  var answer = 0'i64
  var outerWidth = 3'i64
  while outerWidth < maxTiles div 4 + 2:
    var holeWidth = 1'i64
    let outerArea = outerWidth * outerWidth
    if outerArea > maxTiles:
      holeWidth = problem173CeilSqrt(outerArea - maxTiles)
      if holeWidth < 1: holeWidth = 1
    if (outerWidth - holeWidth) mod 2 != 0: inc holeWidth
    answer += (outerWidth - holeWidth - 2) div 2 + 1
    inc outerWidth
  answer
