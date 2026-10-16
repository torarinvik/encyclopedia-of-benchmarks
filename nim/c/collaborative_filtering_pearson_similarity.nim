import std/math

const MaxProfileItems = 32
const MaxInputLength = 2 + 4 * MaxProfileItems
const MaxRatingMilli = 1_000_000_000'i64
const InvalidResult = -2.0

proc collaborative_filtering_pearson_similarity*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "collaborative_filtering_pearson_similarity".} =
  if values == nil or length < 2 or length > csize_t(MaxInputLength): return InvalidResult
  let firstCountValue = values[0]
  if firstCountValue < 0 or firstCountValue > MaxProfileItems: return InvalidResult
  let firstCount = int(firstCountValue)
  let secondCountPosition = 1 + 2 * firstCount
  if csize_t(secondCountPosition) >= length: return InvalidResult
  let secondCountValue = values[secondCountPosition]
  if secondCountValue < 0 or secondCountValue > MaxProfileItems: return InvalidResult
  let secondCount = int(secondCountValue)
  if length != csize_t(secondCountPosition + 1 + 2 * secondCount): return InvalidResult

  var firstIds: array[MaxProfileItems, int64]
  var secondIds: array[MaxProfileItems, int64]
  var firstRatings: array[MaxProfileItems, float64]
  var secondRatings: array[MaxProfileItems, float64]
  for index in 0 ..< firstCount:
    let itemId = values[1 + 2 * index]
    let ratingMilli = values[2 + 2 * index]
    if itemId < 0 or itemId > 127 or ratingMilli < -MaxRatingMilli or ratingMilli > MaxRatingMilli:
      return InvalidResult
    for earlier in 0 ..< index:
      if firstIds[earlier] == itemId: return InvalidResult
    firstIds[index] = itemId
    firstRatings[index] = float64(ratingMilli) / 1000.0
  let secondStart = secondCountPosition + 1
  for index in 0 ..< secondCount:
    let itemId = values[secondStart + 2 * index]
    let ratingMilli = values[secondStart + 2 * index + 1]
    if itemId < 0 or itemId > 127 or ratingMilli < -MaxRatingMilli or ratingMilli > MaxRatingMilli:
      return InvalidResult
    for earlier in 0 ..< index:
      if secondIds[earlier] == itemId: return InvalidResult
    secondIds[index] = itemId
    secondRatings[index] = float64(ratingMilli) / 1000.0

  var commonFirst: array[MaxProfileItems, float64]
  var commonSecond: array[MaxProfileItems, float64]
  var commonCount = 0
  for first in 0 ..< firstCount:
    for second in 0 ..< secondCount:
      if firstIds[first] == secondIds[second]:
        commonFirst[commonCount] = firstRatings[first]
        commonSecond[commonCount] = secondRatings[second]
        inc commonCount
        break
  if commonCount == 0: return 0.0

  var averageFirst = 0.0
  var averageSecond = 0.0
  for index in 0 ..< commonCount:
    averageFirst += commonFirst[index]
    averageSecond += commonSecond[index]
  averageFirst /= float64(commonCount)
  averageSecond /= float64(commonCount)

  var numerator = 0.0
  var sumSquareFirst = 0.0
  var sumSquareSecond = 0.0
  for index in 0 ..< commonCount:
    let differenceFirst = commonFirst[index] - averageFirst
    let differenceSecond = commonSecond[index] - averageSecond
    numerator += differenceFirst * differenceSecond
    sumSquareFirst += differenceFirst * differenceFirst
    sumSquareSecond += differenceSecond * differenceSecond
  let denominator = sqrt(sumSquareFirst * sumSquareSecond)
  if abs(denominator) < 1.0e-10: return 0.0
  numerator / denominator
