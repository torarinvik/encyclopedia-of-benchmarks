import std/math

const MaxUsers = 65
const MaxInputLength = 1 + 4 * MaxUsers
const MaxSimilarityTicks = 1_000_000_000_000'i64
const MaxRatingMilli = 1_000_000_000'i64
const InvalidResult = -1.0e300

proc collaborative_filtering*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "collaborative_filtering".} =
  if values == nil or length < 1 or length > csize_t(MaxInputLength): return InvalidResult
  let countValue = values[0]
  if countValue < 1 or countValue > MaxUsers: return InvalidResult
  let count = int(countValue)
  if length != csize_t(1 + 4 * count): return InvalidResult

  var totalSimilarity = 0.0
  var weightedSum = 0.0
  var targetUserCount = 0
  for index in 0 ..< count:
    let offset = 1 + 4 * index
    let isTargetUser = values[offset]
    let hasTargetRating = values[offset + 1]
    let similarityTicks = values[offset + 2]
    let ratingMilli = values[offset + 3]
    if (isTargetUser != 0 and isTargetUser != 1)
        or (hasTargetRating != 0 and hasTargetRating != 1)
        or similarityTicks < -MaxSimilarityTicks or similarityTicks > MaxSimilarityTicks
        or ratingMilli < -MaxRatingMilli or ratingMilli > MaxRatingMilli:
      return InvalidResult
    if isTargetUser == 1:
      inc targetUserCount
      continue
    if hasTargetRating == 0: continue
    let similarity = float64(similarityTicks) / 1_000_000_000_000.0
    let rating = float64(ratingMilli) / 1000.0
    totalSimilarity += abs(similarity)
    weightedSum += similarity * rating
  if targetUserCount != 1: return InvalidResult
  if abs(totalSimilarity) < 1.0e-10: return 0.0
  weightedSum / totalSimilarity
