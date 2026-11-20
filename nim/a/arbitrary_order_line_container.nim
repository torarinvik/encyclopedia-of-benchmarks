const
  MaxOperations = 32
  MaxInputLength = 99
  BreakpointInfinity = 1_000_000_000_000_000'i64
  ChecksumOffset = 2_000_001'i64

type Line = object
  slope, intercept, breakpoint: int64

proc intersection(left, right: Line): int64 =
  let numerator = left.intercept - right.intercept
  let denominator = right.slope - left.slope
  var quotient = numerator div denominator
  if numerator mod denominator != 0 and numerator < 0: dec quotient
  quotient

proc eraseLine(lines: var array[MaxOperations, Line], count, position: int): int =
  for i in position ..< count - 1: lines[i] = lines[i + 1]
  count - 1

proc insertLine(lines: var array[MaxOperations, Line], initialCount: int,
                slope, intercept: int64): int =
  var count = initialCount
  var position = 0
  while position < count and lines[position].slope < slope: inc position
  if position < count and lines[position].slope == slope:
    if lines[position].intercept >= intercept: return count
    count = eraseLine(lines, count, position)
  for i in countdown(count - 1, position): lines[i + 1] = lines[i]
  lines[position] = Line(slope: slope, intercept: intercept, breakpoint: BreakpointInfinity)
  inc count
  var active = position
  while active + 1 < count:
    let breakpoint = intersection(lines[active], lines[active + 1])
    lines[active].breakpoint = breakpoint
    if breakpoint >= lines[active + 1].breakpoint:
      count = eraseLine(lines, count, active + 1)
    else: break
  if active + 1 == count: lines[active].breakpoint = BreakpointInfinity
  if active > 0:
    let breakpoint = intersection(lines[active - 1], lines[active])
    lines[active - 1].breakpoint = breakpoint
    var cursor: int
    if breakpoint >= lines[active].breakpoint:
      count = eraseLine(lines, count, active)
      dec active
      lines[active].breakpoint = if active + 1 < count:
        intersection(lines[active], lines[active + 1]) else: BreakpointInfinity
      cursor = active
    else:
      cursor = active - 1
    while cursor > 0 and lines[cursor - 1].breakpoint >= lines[cursor].breakpoint:
      count = eraseLine(lines, count, cursor)
      dec cursor
      dec active
      lines[cursor].breakpoint = if cursor + 1 < count:
        intersection(lines[cursor], lines[cursor + 1]) else: BreakpointInfinity
  count

proc lineQuery(lines: array[MaxOperations, Line], count: int, x, objective: int64): int64 =
  var low = 0
  var high = count
  while low < high:
    let middle = low + (high - low) div 2
    if lines[middle].breakpoint < x: low = middle + 1
    else: high = middle
  (lines[low].slope * x + lines[low].intercept) * objective

proc arbitrary_order_line_container*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "arbitrary_order_line_container".} =
  if input == nil or length < 2 or length > csize_t(MaxInputLength): return -1
  let mode = input[0]
  let operationValue = input[1]
  if mode < 0 or mode > 1 or operationValue < 0 or operationValue > MaxOperations: return -1
  let operations = int(operationValue)
  if length != csize_t(2 + 3 * operations): return -1
  var seenLine = false
  for operation in 0 ..< operations:
    let p = 2 + 3 * operation
    let opcode, first, second = input[p], input[p + 1], input[p + 2]
    if opcode == 0:
      if first < -1000 or first > 1000 or second < -1000 or second > 1000: return -1
      seenLine = true
    elif opcode == 1:
      if not seenLine or first < -1000 or first > 1000 or second != 0: return -1
    else: return -1

  let objective = if mode == 1: 1'i64 else: -1'i64
  var lines: array[MaxOperations, Line]
  var lineCount = 0
  var queryIndex = 0
  var checksum = 0'i64
  for operation in 0 ..< operations:
    let p = 2 + 3 * operation
    if input[p] == 0:
      lineCount = insertLine(lines, lineCount, input[p + 1] * objective, input[p + 2] * objective)
    else:
      let optimum = lineQuery(lines, lineCount, input[p + 1], objective)
      checksum += int64(queryIndex + 1) * (optimum + ChecksumOffset)
      inc queryIndex
  checksum
