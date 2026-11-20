type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]

proc squaredDistance(coordinates: openArray[int64], dimension: int,
    row: int, center: int): int64 =
  var distance = 0'i64
  for axis in 0 ..< dimension:
    let difference = coordinates[row * dimension + axis] - coordinates[center * dimension + axis]
    distance += difference * difference
  distance

proc rowIsSelected(centers: array[8, int64], count: int, row: int64): bool =
  for index in 0 ..< count:
    if centers[index] == row: return true
  false

proc storeI64Le(output: U8Output, offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255'u64)

proc kmeans_plus_plus_seeding*(input: I64Input, length: csize_t, output: U8Output,
    outputCapacity: csize_t): int64 {.cdecl, exportc: "kmeans_plus_plus_seeding".} =
  if input == nil or length < 4 or length > 140: return -1
  let pointCountValue = input[0]
  let dimensionValue = input[1]
  let centerCountValue = input[2]
  let firstRow = input[3]
  if pointCountValue < 1 or pointCountValue > 32 or dimensionValue < 1 or dimensionValue > 4
      or centerCountValue < 1 or centerCountValue > 8 or centerCountValue > pointCountValue
      or firstRow < 0 or firstRow >= pointCountValue: return -1

  let pointCount = int(pointCountValue)
  let dimension = int(dimensionValue)
  let centerCount = int(centerCountValue)
  let coordinateCount = pointCount * dimension
  let drawOffset = 4 + coordinateCount
  if int(length) != drawOffset + centerCount - 1: return -1

  var coordinates: array[128, int64]
  for index in 0 ..< coordinateCount:
    let coordinate = input[4 + index]
    if coordinate < -16 or coordinate > 16: return -1
    coordinates[index] = coordinate

  var centers: array[8, int64]
  var nearest: array[32, int64]
  centers[0] = firstRow
  for row in 0 ..< pointCount:
    nearest[row] = squaredDistance(coordinates, dimension, row, int(firstRow))

  for step in 0 ..< (centerCount - 1):
    let draw = input[drawOffset + step]
    var totalWeight = 0'i64
    for row in 0 ..< pointCount: totalWeight += nearest[row]

    var chosen = -1'i64
    if totalWeight == 0:
      if draw != 0: return -1
      for row in 0 ..< pointCount:
        if not rowIsSelected(centers, step + 1, int64(row)):
          chosen = int64(row)
          break
    else:
      if draw < 0 or draw >= totalWeight: return -1
      var cumulative = 0'i64
      for row in 0 ..< pointCount:
        cumulative += nearest[row]
        if cumulative > draw:
          chosen = int64(row)
          break
    if chosen < 0: return -1

    centers[step + 1] = chosen
    for row in 0 ..< pointCount:
      let distance = squaredDistance(coordinates, dimension, row, int(chosen))
      if distance < nearest[row]: nearest[row] = distance

  let outputBytes = centerCount * 8
  if output == nil or outputCapacity < csize_t(outputBytes): return -2
  for index in 0 ..< centerCount:
    storeI64Le(output, index * 8, centers[index])
  int64(outputBytes)
