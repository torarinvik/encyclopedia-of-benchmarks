const MaxFan = 8
const MaxInputLength = 1 + 8 * (MaxFan + 1)

proc validBox(values: ptr UncheckedArray[int64], at: int): bool =
  for d in 0 ..< 4:
    if values[at+d] < -8 or values[at+d] > 8 or values[at+4+d] < -8 or values[at+4+d] > 8 or values[at+d] >= values[at+4+d]: return false
  true
proc volumeAt(values: ptr UncheckedArray[int64], at: int): int64 =
  result = 1
  for d in 0 ..< 4: result *= values[at+4+d] - values[at+d]
proc unionVolume(values: ptr UncheckedArray[int64], left, right: int): int64 =
  result = 1
  for d in 0 ..< 4:
    let lo = min(values[left+d], values[right+d])
    let hi = max(values[left+4+d], values[right+4+d])
    result *= hi - lo
proc penalty(values: ptr UncheckedArray[int64], seed, entry: int): int64 =
  unionVolume(values, seed, entry) - volumeAt(values, seed)

proc versabench_dbms_partition_entries*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "versabench_dbms_partition_entries".} =
  if values == nil or length < 1 or length > csize_t(MaxInputLength + 1): return -1
  if values[0] < 2 or values[0] > MaxFan: return -1
  let fan = int(values[0]); let count = fan + 1
  if length != csize_t(1 + 8 * count): return -1
  for i in 0 ..< count:
    if not validBox(values, 1 + 8 * i): return -1
  var seedA = 0; var seedB = 1
  var largest = unionVolume(values, 1, 9)
  for i in 0 ..< count:
    for j in i+1 ..< count:
      let candidate = unionVolume(values, 1 + 8 * i, 1 + 8 * j)
      if candidate > largest: seedA = i; seedB = j; largest = candidate
  let aAt = 1 + 8 * seedA; let bAt = 1 + 8 * seedB
  var sizeA = 1; var sizeB = 1; var mask = 1'i64 shl seedA
  for i in 0 ..< count:
    if i == seedA or i == seedB: continue
    let at = 1 + 8 * i
    if sizeA < fan and sizeB < fan:
      if penalty(values, aAt, at) < penalty(values, bAt, at): mask = mask or (1'i64 shl i); inc sizeA
      else: inc sizeB
    elif sizeA >= fan and sizeB < fan: inc sizeB
    elif sizeB >= fan and sizeA < fan: mask = mask or (1'i64 shl i); inc sizeA
    else: return -1
  mask
