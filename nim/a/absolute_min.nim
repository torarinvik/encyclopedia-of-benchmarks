const MaxValues = 256
const MaxInputValues = MaxValues + 1
const ValueLimit = 1_000_000_000'i64

proc magnitude(value: int64): int64 =
  if value < 0: -value else: value

proc selectAbsolute(values: ptr UncheckedArray[int64], length: csize_t, chooseMax: bool): int64 =
  if length < 2 or length > MaxInputValues.csize_t: return -1
  let countValue = values[0]
  if countValue < 1 or countValue > MaxValues.int64 or length.int != countValue.int + 1: return -1
  for index in 1 ..< length.int:
    if values[index] < -ValueLimit or values[index] > ValueLimit: return -1
  var best = values[1]
  for index in 2 ..< length.int:
    let candidate = values[index]
    if (chooseMax and magnitude(candidate) > magnitude(best)) or
       (chooseMax and magnitude(candidate) == magnitude(best) and candidate > best) or
       (not chooseMax and magnitude(candidate) < magnitude(best)) or
       (not chooseMax and magnitude(candidate) == magnitude(best) and candidate < best):
      best = candidate
  best

proc absolute_min_benchmark*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "absolute_min_benchmark".} =
  selectAbsolute(values, length, false)
