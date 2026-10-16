const MaxTiles = 1_000_000

proc problem174CeilSqrt(value: int64): int64 =
  if value <= 0: return 0
  var root = value
  var next = (root + value div root) div 2
  while next < root:
    root = next
    next = (root + value div root) div 2
  if root * root == value: root else: root + 1

proc problem174*(tLimit, nLimit: int64): int64 {.cdecl, exportc: "problem174".} =
  if tLimit > MaxTiles: return -1
  if tLimit < 0: return 0
  let bound = int(tLimit)
  var count = newSeq[uint8](bound + 1)
  var outerWidth = 3'i64
  while outerWidth < tLimit div 4 + 2:
    let outerArea = outerWidth * outerWidth
    var holeLower = 1'i64
    if outerArea > tLimit:
      holeLower = problem174CeilSqrt(outerArea - tLimit)
      if holeLower < 1: holeLower = 1
    if (outerWidth - holeLower) mod 2 != 0: inc holeLower
    var holeWidth = holeLower
    while holeWidth < outerWidth - 1:
      let tiles = outerArea - holeWidth * holeWidth
      inc count[int(tiles)]
      holeWidth += 2
    inc outerWidth
  var answer = 0'i64
  for tiles in 1..bound:
    if count[tiles] >= 1 and count[tiles] <= nLimit: inc answer
  answer
