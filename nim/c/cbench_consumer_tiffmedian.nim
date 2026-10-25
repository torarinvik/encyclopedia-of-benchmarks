const BinSide = 32
const HistogramSize = BinSide * BinSide * BinSide
const MaxPalette = 8
const MaxPixels = 16
const MaxInputLength = 50

type ColorBox = object
  rmin, rmax, gmin, gmax, bmin, bmax, total: int

proc histAt(histogram: ptr UncheckedArray[int32], r, g, b: int): int =
  int(histogram[(r * BinSide + g) * BinSide + b])

proc shrinkBox(histogram: ptr UncheckedArray[int32], box: var ColorBox) =
  var rmin, gmin, bmin = BinSide
  var rmax = -1
  var gmax = -1
  var bmax = -1
  for r in box.rmin..box.rmax:
    for g in box.gmin..box.gmax:
      for b in box.bmin..box.bmax:
        if histAt(histogram, r, g, b) != 0:
          if r < rmin: rmin = r
          if r > rmax: rmax = r
          if g < gmin: gmin = g
          if g > gmax: gmax = g
          if b < bmin: bmin = b
          if b > bmax: bmax = b
  box.rmin = rmin; box.rmax = rmax
  box.gmin = gmin; box.gmax = gmax
  box.bmin = bmin; box.bmax = bmax

proc largestBox(boxes: array[MaxPalette, ColorBox], count: int): int =
  var selected = -1
  var largestTotal = -1
  for i in 0..<count:
    let box = boxes[i]
    if (box.rmax > box.rmin or box.gmax > box.gmin or box.bmax > box.bmin) and box.total > largestTotal:
      selected = i
      largestTotal = box.total
  selected

proc splitBox(histogram: ptr UncheckedArray[int32], boxes: var array[MaxPalette, ColorBox], count: var int, selected: int) =
  var upper = boxes[selected]
  let rspan = upper.rmax - upper.rmin
  let gspan = upper.gmax - upper.gmin
  let bspan = upper.bmax - upper.bmin
  var axis = 0
  if not (rspan >= gspan and rspan >= bspan):
    axis = if gspan >= bspan: 1 else: 2
  let first = if axis == 0: upper.rmin elif axis == 1: upper.gmin else: upper.bmin
  let last = if axis == 0: upper.rmax elif axis == 1: upper.gmax else: upper.bmax
  var along: array[BinSide, int]
  for r in upper.rmin..upper.rmax:
    for g in upper.gmin..upper.gmax:
      for b in upper.bmin..upper.bmax:
        let coordinate = if axis == 0: r elif axis == 1: g else: b
        along[coordinate] += histAt(histogram, r, g, b)
  let median = upper.total div 2
  var accumulated = 0
  var split = first
  while split <= last:
    accumulated += along[split]
    if accumulated >= median: break
    inc split
  if split == first: inc split
  var lower = upper
  var lowerTotal = 0
  var upperTotal = 0
  for bin in first..<split: lowerTotal += along[bin]
  for bin in split..last: upperTotal += along[bin]
  lower.total = lowerTotal; upper.total = upperTotal
  if axis == 0: lower.rmax = split - 1; upper.rmin = split
  elif axis == 1: lower.gmax = split - 1; upper.gmin = split
  else: lower.bmax = split - 1; upper.bmin = split
  shrinkBox(histogram, lower)
  shrinkBox(histogram, upper)
  boxes[selected] = upper
  for i in countdown(count, 1): boxes[i] = boxes[i - 1]
  boxes[0] = lower
  inc count

proc cbench_consumer_tiffmedian*(input: ptr UncheckedArray[int64], inputLength: csize_t,
                                 output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64 {.cdecl, exportc: "cbench_consumer_tiffmedian".} =
  if input == nil or inputLength < 5 or inputLength > MaxInputLength: return -1
  let paletteValue = input[0]
  let pixelValue = input[1]
  if paletteValue < 1 or paletteValue > MaxPalette or pixelValue < 1 or pixelValue > MaxPixels: return -1
  let paletteLimit = int(paletteValue)
  let pixelCount = int(pixelValue)
  if inputLength != csize_t(2 + 3 * pixelCount): return -1
  for i in 0..<3*pixelCount:
    if input[i + 2] < 0 or input[i + 2] > 255: return -1

  var histogram: array[HistogramSize, int32]
  var boxes: array[MaxPalette, ColorBox]
  var rmin = BinSide; var gmin = BinSide; var bmin = BinSide
  var rmax = -1; var gmax = -1; var bmax = -1
  for p in 0..<pixelCount:
    let r = int(input[2 + 3*p] shr 3)
    let g = int(input[3 + 3*p] shr 3)
    let b = int(input[4 + 3*p] shr 3)
    inc histogram[(r*BinSide+g)*BinSide+b]
    if r < rmin: rmin = r
    if r > rmax: rmax = r
    if g < gmin: gmin = g
    if g > gmax: gmax = g
    if b < bmin: bmin = b
    if b > bmax: bmax = b
  boxes[0] = ColorBox(rmin: rmin, rmax: rmax, gmin: gmin, gmax: gmax, bmin: bmin, bmax: bmax, total: pixelCount)
  var boxCount = 1
  let histPtr = cast[ptr UncheckedArray[int32]](addr histogram[0])
  while boxCount < paletteLimit:
    let selected = largestBox(boxes, boxCount)
    if selected < 0: break
    splitBox(histPtr, boxes, boxCount, selected)
  let outputBytes = 1 + 3 * boxCount
  if output == nil or outputCapacity < csize_t(outputBytes): return -2
  output[0] = uint8(boxCount)
  for i in 0..<boxCount:
    output[1+3*i] = uint8((boxes[i].rmin+boxes[i].rmax)*4)
    output[2+3*i] = uint8((boxes[i].gmin+boxes[i].gmax)*4)
    output[3+3*i] = uint8((boxes[i].bmin+boxes[i].bmax)*4)
  int64(outputBytes)
