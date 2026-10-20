# Adapted from Trekhleb's seam-carving explanation. Copyright (c) 2018
# Oleksii Trekhleb; MIT License, see benchmarks/s/seam_carving/LICENSE.txt.
import std/math

proc seam_carving*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "seam_carving".} =
  if input == nil or length < 2 or length > 39: return -1
  let widthValue = input[0]
  let heightValue = input[1]
  if widthValue < 2 or widthValue > 6 or heightValue < 1 or heightValue > 6: return -1
  let width = int(widthValue)
  let height = int(heightValue)
  if int(length) != 2 + width * height: return -1
  for index in 0 ..< width * height:
    if input[2 + index] < 0 or input[2 + index] > 255: return -1

  var energy: array[6, array[6, float64]]
  var cumulative: array[6, array[6, float64]]
  var previousX: array[6, array[6, int]]
  var seamX: array[6, int]
  for y in 0 ..< height:
    let row = y * width
    for x in 0 ..< width:
      let middle = float64(input[2 + row + x])
      var leftEnergy = 0.0
      var rightEnergy = 0.0
      if x > 0:
        let difference = float64(input[2 + row + x - 1]) - middle
        leftEnergy = difference * difference + difference * difference + difference * difference
      if x + 1 < width:
        let difference = float64(input[2 + row + x + 1]) - middle
        rightEnergy = difference * difference + difference * difference + difference * difference
      energy[y][x] = sqrt(leftEnergy + rightEnergy)
  for x in 0 ..< width: cumulative[0][x] = energy[0][x]
  for y in 1 ..< height:
    for x in 0 ..< width:
      var minimum = Inf
      var bestX = x
      let start = if x == 0: 0 else: x - 1
      let last = if x + 1 < width: x + 1 else: width - 1
      for candidate in start .. last:
        if cumulative[y - 1][candidate] < minimum:
          minimum = cumulative[y - 1][candidate]
          bestX = candidate
      cumulative[y][x] = minimum + energy[y][x]
      previousX[y][x] = bestX
  var lastX = 0
  var minimum = cumulative[height - 1][0]
  for x in 1 ..< width:
    if cumulative[height - 1][x] < minimum:
      minimum = cumulative[height - 1][x]
      lastX = x
  seamX[height - 1] = lastX
  var y = height - 1
  while y > 0:
    seamX[y - 1] = previousX[y][seamX[y]]
    dec y

  let needed = height * (width - 1)
  if output == nil or int(outputCapacity) < needed: return -2
  var staged: array[30, uint8]
  var position = 0
  for rowIndex in 0 ..< height:
    for x in 0 ..< width:
      if x != seamX[rowIndex]:
        staged[position] = uint8(input[2 + rowIndex * width + x])
        inc position
  for index in 0 ..< needed: output[index] = staged[index]
  int64(needed)
