## Rodinia DWT2D (Jiri Matela, Martin Jirman); complete notices in
## benchmarks/r/rodinia_dwt2d/LICENSE.txt. Independent scalar 5/3 lifting port.
const MaxSide = 16
const MaxCells = MaxSide * MaxSide
const MaxInput = 3 + MaxCells

proc divTrunc(numerator, denominator: int64): int64 =
  if numerator < 0: -( (-numerator) div denominator ) else: numerator div denominator

proc transformLine(line: array[MaxSide, int64], n: int): array[MaxSide, int64] =
  var detail: array[MaxSide div 2, int64]
  let half = n div 2
  for j in 0 ..< half:
    let even = line[2 * j]
    let right = if j + 1 < half: line[2 * j + 2] else: even
    detail[j] = line[2 * j + 1] - divTrunc(even + right, 2)
  result[0] = line[0] + divTrunc(detail[0] + detail[0] + 2, 4)
  for j in 1 ..< half:
    result[j] = line[2 * j] + divTrunc(detail[j - 1] + detail[j] + 2, 4)
  for j in 0 ..< half:
    result[half + j] = detail[j]

proc putI32Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint32](int32(value))
  for byte in 0 ..< 4:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u32)

proc rodinia_dwt2d*(values: ptr UncheckedArray[int64], length: csize_t,
                    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "rodinia_dwt2d".} =
  if values == nil or length < 3 or length > MaxInput.csize_t: return -1
  let wi = values[0]
  let hi = values[1]
  let li = values[2]
  if wi < 2 or wi > MaxSide or hi < 2 or hi > MaxSide or li < 1 or li > 3: return -1
  let factor = 1'i64 shl int(li)
  if wi < factor or hi < factor or wi mod factor != 0 or hi mod factor != 0: return -1
  let width = int(wi)
  let height = int(hi)
  let cells = width * height
  if length != (3 + cells).csize_t: return -1
  for i in 0 ..< cells:
    if values[3 + i] < 0 or values[3 + i] > 255: return -1
  let outputBytes = cells * 4
  if output == nil or capacity < outputBytes.csize_t: return -2

  var plane, vertical, next, ordered: array[MaxCells, int64]
  var line: array[MaxSide, int64]
  for i in 0 ..< cells: plane[i] = values[3 + i] - 128
  var activeWidth = width
  var activeHeight = height
  for level in 0 ..< int(li):
    for x in 0 ..< activeWidth:
      for y in 0 ..< activeHeight: line[y] = plane[y * width + x]
      let transformed = transformLine(line, activeHeight)
      for y in 0 ..< activeHeight: vertical[y * width + x] = transformed[y]
    for y in 0 ..< activeHeight:
      for x in 0 ..< activeWidth: line[x] = vertical[y * width + x]
      let transformed = transformLine(line, activeWidth)
      for x in 0 ..< activeWidth: next[y * width + x] = transformed[x]
    for y in 0 ..< activeHeight:
      for x in 0 ..< activeWidth: plane[y * width + x] = next[y * width + x]
    activeWidth = activeWidth div 2
    activeHeight = activeHeight div 2
  var outputIndex = 0
  for stage in countdown(int(li) - 1, 0):
    let stageWidth = width shr stage
    let stageHeight = height shr stage
    let halfWidth = stageWidth div 2
    let halfHeight = stageHeight div 2
    if stage == int(li) - 1:
      for y in 0 ..< halfHeight:
        for x in 0 ..< halfWidth:
          ordered[outputIndex] = plane[y * width + x]
          inc outputIndex
    for y in 0 ..< halfHeight:
      for x in halfWidth ..< stageWidth:
        ordered[outputIndex] = plane[y * width + x]
        inc outputIndex
    for y in halfHeight ..< stageHeight:
      for x in 0 ..< halfWidth:
        ordered[outputIndex] = plane[y * width + x]
        inc outputIndex
    for y in halfHeight ..< stageHeight:
      for x in halfWidth ..< stageWidth:
        ordered[outputIndex] = plane[y * width + x]
        inc outputIndex
  for i in 0 ..< cells: putI32Le(output, 4 * i, ordered[i])
  int64(outputBytes)
