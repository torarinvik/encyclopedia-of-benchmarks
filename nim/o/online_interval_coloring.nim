# Clean-room bounded Kierstead-Trotter online interval coloring profile.
const MaxN = 64
const MaxInput = 129

proc storeI64LE(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8: output[offset + byte] = uint8((bits shr (byte * 8)) and 255)

proc levelFits(left, right: array[MaxN, int64], levels: array[MaxN, int], last, candidate: int): bool =
  for anchor in 0..last:
    let point = left[anchor]
    var overlap = 0
    for item in 0..last:
      if (item == last or levels[item] <= candidate) and left[item] <= point and point <= right[item]: inc overlap
    if overlap > candidate: return false
  true

proc online_interval_coloring*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "online_interval_coloring".} =
  if input.isNil or length < csize_t(1) or length > csize_t(MaxInput): return -1
  let count = input[0]
  if count < 0 or count > int64(MaxN) or int64(length) != 1 + 2 * count: return -1
  let n = int(count)
  var left, right: array[MaxN, int64]
  for i in 0..<n:
    left[i] = input[1 + 2*i]; right[i] = input[2 + 2*i]
    if left[i] < -1000 or left[i] > 1000 or right[i] < -1000 or right[i] > 1000 or left[i] > right[i]: return -1
  let outputBytes = 8*n
  if output.isNil or capacity < csize_t(outputBytes): return -2
  var levels, local, colors: array[MaxN, int]
  for i in 0..<n:
    var level = 1
    while not levelFits(left, right, levels, i, level):
      inc level
      if level > i + 1: return -1
    levels[i] = level
    var used: array[3, bool]
    for j in 0..<i:
      if levels[j] == level and left[j] <= right[i] and left[i] <= right[j] and local[j] < 3:
        used[local[j]] = true
    var color = 0
    while color < 3 and used[color]: inc color
    if color == 3: return -1
    local[i] = color; colors[i] = 3*(level-1)+color
  for i in 0..<n: storeI64LE(output, 8*i, int64(colors[i]))
  int64(outputBytes)
