const MaxDepth = 5

proc factor(tx, ty, sourceArea, sx, sy, gap: float64): float64 =
  let distanceSquared = (sx - tx) * (sx - tx) + (sy - ty) * (sy - ty) + gap * gap
  sourceArea * gap * gap / (distanceSquared * distanceSquared)

proc visit(tx, ty, targetSide, sx, sy, sourceSide, gap, bound: float64,
           allowedDepth, depth: int, weight: float64,
           transfer: var float64, leaves: var int, deepest: var int) =
  let coarse = factor(tx, ty, sourceSide * sourceSide, sx, sy, gap)
  let splitSource = sourceSide >= targetSide
  let parentSide = if splitSource: sourceSide else: targetSide
  let childSide = parentSide * 0.5
  let offset = parentSide * 0.25
  var fine = 0.0
  for quadrant in 0 ..< 4:
    let dx = if (quadrant and 1) != 0: offset else: -offset
    let dy = if (quadrant and 2) != 0: offset else: -offset
    if splitSource:
      fine += factor(tx, ty, childSide * childSide, sx + dx, sy + dy, gap)
    else:
      fine += 0.25 * factor(tx + dx, ty + dy, sourceSide * sourceSide, sx, sy, gap)
  if depth >= allowedDepth or abs(fine - coarse) <= bound:
    transfer += weight * coarse
    inc leaves
    deepest = max(deepest, depth)
    return
  for quadrant in 0 ..< 4:
    let dx = if (quadrant and 1) != 0: offset else: -offset
    let dy = if (quadrant and 2) != 0: offset else: -offset
    if splitSource:
      visit(tx, ty, targetSide, sx + dx, sy + dy, childSide, gap, bound,
            allowedDepth, depth + 1, weight, transfer, leaves, deepest)
    else:
      visit(tx + dx, ty + dy, childSide, sx, sy, sourceSide, gap, bound,
            allowedDepth, depth + 1, weight * 0.25, transfer, leaves, deepest)

proc splash2_radiosity_refine*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64 {.cdecl, exportc: "splash2_radiosity_refine".} =
  if input == nil or inputLength != 11: return -1
  for i in 0 ..< int(inputLength):
    if input[i] != input[i]: return -1
  let tx=input[0]; let ty=input[1]; let targetSide=input[2]
  let sx=input[3]; let sy=input[4]; let sourceSide=input[5]
  let gap=input[6]; let brightness=input[7]; let reflectance=input[8]
  let bound=input[9]; let depthValue=input[10]
  if tx < -8 or tx > 8 or ty < -8 or ty > 8 or sx < -8 or sx > 8 or sy < -8 or sy > 8
      or (targetSide != 1 and targetSide != 2 and targetSide != 4)
      or (sourceSide != 1 and sourceSide != 2 and sourceSide != 4)
      or gap < 1 or gap > 8 or targetSide > gap or sourceSide > gap
      or brightness < 0 or brightness > 4 or reflectance < 0 or reflectance > 1
      or bound < 0 or bound > 1 or depthValue < 0 or depthValue > float64(MaxDepth)
      or depthValue != float64(int(depthValue)): return -1
  if output == nil or outputCapacity < 3: return -2
  var transfer = 0.0
  var leaves = 0
  var deepest = 0
  visit(tx, ty, targetSide, sx, sy, sourceSide, gap, bound,
        int(depthValue), 0, 1.0, transfer, leaves, deepest)
  output[0] = reflectance * brightness * transfer
  output[1] = float64(leaves)
  output[2] = float64(deepest)
  3
