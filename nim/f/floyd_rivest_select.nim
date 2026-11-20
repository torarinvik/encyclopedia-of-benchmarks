import std/math

const MaxValues = 64
const MaxInputLength = MaxValues + 3
const SampleCutoff = 24

proc selectKth(values: var array[MaxValues, int64], initialLeft, initialRight,
    target: int): int64 =
  var left = initialLeft
  var right = initialRight
  while true:
    if right - left > SampleCutoff:
      let size = right - left + 1
      let relativeRank = target - left + 1
      let sizeFloat = float64(size)
      let rankFloat = float64(relativeRank)
      let z = sqrt(ln(sizeFloat))
      let sampleSize = 0.5 * exp(2.0 * z / 3.0)
      var direction = 0.0
      if rankFloat < sizeFloat / 2.0: direction = -1.0
      elif rankFloat > sizeFloat / 2.0: direction = 1.0
      let spread = 0.5 * sqrt(z * sampleSize * (sizeFloat - sampleSize) /
        sizeFloat) * direction
      let lowerEstimate = float64(target) - rankFloat * sampleSize /
        sizeFloat + spread
      let upperEstimate = float64(target) + (sizeFloat - rankFloat) *
        sampleSize / sizeFloat + spread
      let sampleLeft = max(left, min(target, int(floor(lowerEstimate))))
      let sampleRight = min(right, max(target, int(ceil(upperEstimate))))
      discard selectKth(values, sampleLeft, sampleRight, target)

    let pivot = values[target]
    var less = left
    var scan = left
    var greater = right
    while scan <= greater:
      if values[scan] < pivot:
        swap(values[less], values[scan])
        inc less
        inc scan
      elif values[scan] > pivot:
        swap(values[scan], values[greater])
        dec greater
      else:
        inc scan
    if target < less:
      right = less - 1
    elif target > greater:
      left = greater + 1
    else:
      return pivot

proc floyd_rivest_select*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "floyd_rivest_select".} =
  if input.isNil or length < 3 or length > csize_t(MaxInputLength): return -1
  let countValue = input[0]
  let rankValue = input[1]
  if countValue < 1 or countValue > int64(MaxValues) or rankValue < 0 or
      rankValue >= countValue:
    return -1
  let count = int(countValue)
  if length != csize_t(count + 2): return -1

  var values: array[MaxValues, int64]
  for index in 0 ..< count:
    let value = input[index + 2]
    if value < 0 or value > 2_147_483_647: return -1
    for previous in 0 ..< index:
      if values[previous] == value: return -1
    values[index] = value
  selectKth(values, 0, count - 1, int(rankValue))
