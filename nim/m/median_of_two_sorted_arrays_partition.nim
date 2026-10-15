## Find twice the median by binary-searching a partition of the shorter sorted array.
const MaxArrayLength = 1000

proc median_of_two_sorted_arrays_partition*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "median_of_two_sorted_arrays_partition".} =
  if input == nil or length < 3 or length > 2 * MaxArrayLength + 2: return -2_000_001
  if input[0] < 0 or input[0] > MaxArrayLength or input[1] < 0 or input[1] > MaxArrayLength: return -2_000_001

  let firstCount = int(input[0])
  let secondCount = int(input[1])
  let totalCount = firstCount + secondCount
  if totalCount == 0 or totalCount > 2 * MaxArrayLength or int(length) != totalCount + 2: return -2_000_001
  let secondStart = firstCount + 2
  for index in 0 ..< firstCount:
    let value = input[index + 2]
    if value < -1_000_000 or value > 1_000_000 or
        (index > 0 and input[index + 1] > value): return -2_000_001
  for index in 0 ..< secondCount:
    let value = input[secondStart + index]
    if value < -1_000_000 or value > 1_000_000 or
        (index > 0 and input[secondStart + index - 1] > value): return -2_000_001

  var firstStart = 2
  var secondArrayStart = secondStart
  var shortCount = firstCount
  var longCount = secondCount
  if shortCount > longCount:
    swap(firstStart, secondArrayStart)
    swap(shortCount, longCount)

  var lowCut = 0
  var highCut = shortCount
  let leftCount = (totalCount + 1) div 2
  while lowCut <= highCut:
    let firstCut = lowCut + (highCut - lowCut) div 2
    let secondCut = leftCount - firstCut
    let firstLeft = if firstCut == 0: low(int64) else: input[firstStart + firstCut - 1]
    let firstRight = if firstCut == shortCount: high(int64) else: input[firstStart + firstCut]
    let secondLeft = if secondCut == 0: low(int64) else: input[secondArrayStart + secondCut - 1]
    let secondRight = if secondCut == longCount: high(int64) else: input[secondArrayStart + secondCut]

    if firstLeft <= secondRight and secondLeft <= firstRight:
      let leftMax = max(firstLeft, secondLeft)
      if totalCount mod 2 != 0: return leftMax * 2
      let rightMin = min(firstRight, secondRight)
      return leftMax + rightMin
    if firstLeft > secondRight:
      if firstCut == 0: return -2_000_001
      highCut = firstCut - 1
    else:
      lowCut = firstCut + 1
  -2_000_001
