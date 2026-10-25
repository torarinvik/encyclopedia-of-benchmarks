## Copyright (c) 2012-2013 Argonne National Laboratory
##
## Permission is hereby granted, free of charge, to any person obtaining a copy
## of this software and associated documentation files (the "Software"), to deal
## in the Software without restriction, including without limitation the rights
## to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
## of the Software, and to permit persons to whom the Software is furnished to do so,
## subject to the following conditions:
##
## The above copyright notice and this permission notice shall be included in all
## copies or substantial portions of the Software.
##
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
## IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
## FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
## COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
## IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
## CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

const InvalidResult = -1.0e300
const MaxNuclides = 4
const MinGridpoints = 2
const MaxGridpoints = 5
const MaxUnionPoints = MaxNuclides * MaxGridpoints
const MaxLength = 232
const RecordSize = 6
const ScaleQ = 1_000_000.0

proc decode(raw: int64): float64 = float64(raw) / ScaleQ

proc binarySearch(energies: array[MaxNuclides * MaxGridpoints, int64],
                  nuclide, gridpoints: int, quarry: int64): int =
  var minimum = 0
  var maximum = gridpoints - 1
  let base = nuclide * MaxGridpoints
  if energies[base] > quarry: return 0
  if energies[base + gridpoints - 1] < quarry: return gridpoints - 2
  while maximum >= minimum:
    let middle = minimum + (maximum - minimum) div 2
    if energies[base + middle] < quarry:
      minimum = middle + 1
    elif energies[base + middle] > quarry:
      maximum = middle - 1
    else:
      return middle
  maximum

proc gridSearch(grid: array[MaxUnionPoints, int64], count: int, quarry: int64): int =
  var lower = 0
  var upper = count - 1
  var span = upper - lower
  while span > 1:
    let middle = lower + span div 2
    if grid[middle] > quarry:
      upper = middle
    else:
      lower = middle
    span = upper - lower
  lower

proc doe_xsbench_unionized_macro_xs*(input: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "doe_xsbench_unionized_macro_xs".} =
  if input.isNil or length < csize_t(22) or length > csize_t(MaxLength): return InvalidResult
  let nuclidesRaw = input[0]
  let gridpointsRaw = input[1]
  let materialNuclidesRaw = input[2]
  let queryRaw = input[3]
  if nuclidesRaw < 1 or nuclidesRaw > MaxNuclides or
      gridpointsRaw < MinGridpoints or gridpointsRaw > MaxGridpoints or
      materialNuclidesRaw < 1 or materialNuclidesRaw > nuclidesRaw or
      queryRaw < 0 or queryRaw > 1_000_000:
    return InvalidResult

  let nuclides = int(nuclidesRaw)
  let gridpoints = int(gridpointsRaw)
  let materialNuclides = int(materialNuclidesRaw)
  let unionPoints = nuclides * gridpoints
  let compositionStart = 4
  let unionStart = compositionStart + 2 * materialNuclides
  let pointerStart = unionStart + unionPoints
  let gridStart = pointerStart + unionPoints * nuclides
  if int(length) != gridStart + unionPoints * RecordSize: return InvalidResult

  var compositionIds: array[MaxNuclides, int]
  var concentrations: array[MaxNuclides, float64]
  var used: array[MaxNuclides, bool]
  for item in 0 ..< materialNuclides:
    let idRaw = input[compositionStart + 2 * item]
    let concentrationRaw = input[compositionStart + 2 * item + 1]
    if idRaw < 0 or idRaw >= nuclidesRaw or concentrationRaw < 0 or concentrationRaw > 1_000_000:
      return InvalidResult
    let id = int(idRaw)
    if used[id]: return InvalidResult
    used[id] = true
    compositionIds[item] = id
    concentrations[item] = decode(concentrationRaw)

  var unionGrid: array[MaxUnionPoints, int64]
  for index in 0 ..< unionPoints:
    let energy = input[unionStart + index]
    if energy < 0 or energy > 1_000_000 or (index > 0 and energy <= unionGrid[index - 1]):
      return InvalidResult
    unionGrid[index] = energy

  var nuclideEnergies: array[MaxNuclides * MaxGridpoints, int64]
  for nuclide in 0 ..< nuclides:
    for point in 0 ..< gridpoints:
      let record = gridStart + (nuclide * gridpoints + point) * RecordSize
      let energy = input[record]
      let energySlot = nuclide * MaxGridpoints + point
      if energy < 0 or energy > 1_000_000 or
          (point > 0 and energy <= nuclideEnergies[energySlot - 1]):
        return InvalidResult
      nuclideEnergies[energySlot] = energy
      for channel in 1 ..< RecordSize:
        if input[record + channel] < 0 or input[record + channel] > 1_000_000:
          return InvalidResult

  for unionIndex in 0 ..< unionPoints:
    var matches = 0
    for nuclide in 0 ..< nuclides:
      for point in 0 ..< gridpoints:
        if nuclideEnergies[nuclide * MaxGridpoints + point] == unionGrid[unionIndex]:
          inc matches
    if matches != 1: return InvalidResult
    for nuclide in 0 ..< nuclides:
      let pointer = input[pointerStart + unionIndex * nuclides + nuclide]
      if pointer != int64(binarySearch(nuclideEnergies, nuclide, gridpoints, unionGrid[unionIndex])):
        return InvalidResult

  let queryIndex = gridSearch(unionGrid, unionPoints, queryRaw)
  var macroXs: array[5, float64]
  let query = decode(queryRaw)
  for item in 0 ..< materialNuclides:
    let nuclide = compositionIds[item]
    let pointer = int(input[pointerStart + queryIndex * nuclides + nuclide])
    let lowIndex = if pointer == gridpoints - 1: pointer - 1 else: pointer
    let lowRecord = gridStart + (nuclide * gridpoints + lowIndex) * RecordSize
    let highRecord = lowRecord + RecordSize
    let lowEnergy = decode(input[lowRecord])
    let highEnergy = decode(input[highRecord])
    let factor = (highEnergy - query) / (highEnergy - lowEnergy)
    for channel in 0 ..< 5:
      let lowXs = decode(input[lowRecord + channel + 1])
      let highXs = decode(input[highRecord + channel + 1])
      let microscopic = highXs - factor * (highXs - lowXs)
      macroXs[channel] += microscopic * concentrations[item]
  macroXs[0] + 2.0 * macroXs[1] + 3.0 * macroXs[2] + 5.0 * macroXs[3] + 7.0 * macroXs[4]
