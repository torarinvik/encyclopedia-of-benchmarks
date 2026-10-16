const MaxSide = 128
const MaxCells = MaxSide * MaxSide
const MaxInputLength = 3 + 3 * MaxCells

proc isTargetColor(red, green, blue, profile: int64): bool =
  let maximum = max(red, max(green, blue))
  let minimum = min(red, min(green, blue))
  let delta = maximum - minimum
  let hueMinimum = if profile == 0: 379'i64 else: 398'i64
  let hueMaximum = if profile == 0: 496'i64 else: 498'i64
  let saturationMinimum = if profile == 0: 436'i64 else: 355'i64
  if maximum == 0 or delta == 0 or 1000 * delta < saturationMinimum * maximum:
    return false
  var hueNumerator: int64
  if maximum == red:
    hueNumerator = (green - blue) mod (6 * delta)
    if hueNumerator < 0: hueNumerator += 6 * delta
  elif maximum == green:
    hueNumerator = 2 * delta + blue - red
  else:
    hueNumerator = 4 * delta + red - green
  hueMinimum * 6 * delta <= 1000 * hueNumerator and
    1000 * hueNumerator <= hueMaximum * 6 * delta

proc blob_detection*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "blob_detection".} =
  if input.isNil or length < 3 or length > MaxInputLength.csize_t: return -1
  let heightValue = input[0]
  let widthValue = input[1]
  let profile = input[2]
  if heightValue < 1 or heightValue > MaxSide or
      widthValue < 1 or widthValue > MaxSide: return -1
  let height = int(heightValue)
  let width = int(widthValue)
  let cells = height * width
  if profile notin 0'i64 .. 1'i64 or length != csize_t(3 + 3 * cells): return -1
  for channel in 0 ..< 3 * cells:
    if input[3 + channel] < 0 or input[3 + channel] > 255: return -1

  var mask: array[MaxCells, bool]
  var eroded: array[MaxCells, bool]
  var opened: array[MaxCells, bool]
  var visited: array[MaxCells, bool]
  var queue: array[MaxCells, int]
  for index in 0 ..< cells:
    mask[index] = isTargetColor(input[3 + 3 * index], input[4 + 3 * index],
                                input[5 + 3 * index], profile)

  for row in 0 ..< height:
    for column in 0 ..< width:
      var keep = true
      for dy in -3 .. 3:
        for dx in -3 .. 3:
          if dx * dx + dy * dy > 9: continue
          let y = row + dy
          let x = column + dx
          if y >= 0 and y < height and x >= 0 and x < width and
              not mask[y * width + x]:
            keep = false
      eroded[row * width + column] = keep

  for row in 0 ..< height:
    for column in 0 ..< width:
      var set = false
      for dy in -3 .. 3:
        for dx in -3 .. 3:
          if dx * dx + dy * dy > 9: continue
          let y = row + dy
          let x = column + dx
          if y >= 0 and y < height and x >= 0 and x < width and
              eroded[y * width + x]:
            set = true
      opened[row * width + column] = set

  var objectCount = 0'i64
  for start in 0 ..< cells:
    if not opened[start] or visited[start]: continue
    var head = 0
    var tail = 0
    var area = 0
    visited[start] = true
    queue[tail] = start
    inc tail
    while head < tail:
      let index = queue[head]
      inc head
      inc area
      let row = index div width
      let column = index mod width
      for rowDelta in -1 .. 1:
        for columnDelta in -1 .. 1:
          if rowDelta == 0 and columnDelta == 0: continue
          let y = row + rowDelta
          let x = column + columnDelta
          if y >= 0 and y < height and x >= 0 and x < width:
            let neighbor = y * width + x
            if opened[neighbor] and not visited[neighbor]:
              visited[neighbor] = true
              queue[tail] = neighbor
              inc tail
    if area >= 200 and area <= 5000:
      inc objectCount
      if objectCount == 50: return objectCount
  objectCount
