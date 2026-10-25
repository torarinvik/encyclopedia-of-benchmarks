## Independent bounded implementation of John Walker's Floating Point
## Benchmark, from the Marinchip Interactive Lens Design System (December
## 1980). Pinned source: lac-dcc/Benchmarks/Misc/fbench/fbench.c at commit
## 5d7b75df749241efa7a6e6f5be613d3fcc5cce38. The source permits use,
## distribution, and modification while preserving origin information.
import std/math

const
  MaxPasses = 16'i64
  InvalidResult = -1.0e300
  SpectralLine: array[9, float64] = [0.0, 7621.0, 6869.955, 6562.816, 5895.944,
    5269.557, 4861.344, 4340.477, 3968.494]
  Lens: array[4, array[4, float64]] = [
    [27.05, 1.5137, 63.6, 0.52],
    [-16.68, 1.0, 0.0, 0.138],
    [-16.68, 1.6164, 36.7, 0.38],
    [-78.1, 1.0, 0.0, 0.0]
  ]

type RayState = tuple[objectDistance: float64, axisSlopeAngle: float64]

proc traceLine(line: int, initialHeight: float64, paraxial: bool): RayState =
  var objectDistance = 0.0
  var rayHeight = initialHeight
  var axisSlopeAngle = 0.0
  var fromIndex = 1.0
  for surface in 0 ..< 4:
    let radius = Lens[surface][0]
    let nominalIndex = Lens[surface][1]
    let abbeNumber = Lens[surface][2]
    let thickness = Lens[surface][3]
    var toIndex = nominalIndex
    if toIndex > 1.0:
      toIndex += ((SpectralLine[4] - SpectralLine[line])
        / (SpectralLine[3] - SpectralLine[6]))
        * ((nominalIndex - 1.0) / abbeNumber)

    if paraxial:
      if radius != 0.0:
        var incidenceSine: float64
        if objectDistance == 0.0:
          axisSlopeAngle = 0.0
          incidenceSine = rayHeight / radius
        else:
          incidenceSine = ((objectDistance - radius) / radius) * axisSlopeAngle
        let refractionSine = (fromIndex / toIndex) * incidenceSine
        let oldAxisSlopeAngle = axisSlopeAngle
        axisSlopeAngle = axisSlopeAngle + incidenceSine - refractionSine
        if objectDistance != 0.0: rayHeight = objectDistance * oldAxisSlopeAngle
        objectDistance = rayHeight / axisSlopeAngle
      else:
        objectDistance = objectDistance * (toIndex / fromIndex)
        axisSlopeAngle = axisSlopeAngle * (fromIndex / toIndex)
    elif radius != 0.0:
      var incidenceSine: float64
      if objectDistance == 0.0:
        axisSlopeAngle = 0.0
        incidenceSine = rayHeight / radius
      else:
        incidenceSine = ((objectDistance - radius) / radius) * sin(axisSlopeAngle)
      let incidenceAngle = arcsin(incidenceSine)
      let refractionSine = (fromIndex / toIndex) * incidenceSine
      let oldAxisSlopeAngle = axisSlopeAngle
      axisSlopeAngle = axisSlopeAngle + incidenceAngle - arcsin(refractionSine)
      var sagitta = sin((oldAxisSlopeAngle + incidenceAngle) / 2.0)
      sagitta = 2.0 * radius * sagitta * sagitta
      objectDistance = (radius * sin(oldAxisSlopeAngle + incidenceAngle))
        * (1.0 / tan(axisSlopeAngle)) + sagitta
    else:
      let refractionAngle = -arcsin((fromIndex / toIndex) * sin(axisSlopeAngle))
      objectDistance = objectDistance * ((toIndex * cos(-refractionAngle))
        / (fromIndex * cos(axisSlopeAngle)))
      axisSlopeAngle = -refractionAngle

    fromIndex = toIndex
    if surface < 3: objectDistance = objectDistance - thickness
  (objectDistance, axisSlopeAngle)

proc onePassProjection(rayHeight: float64): float64 =
  let marginalD = traceLine(4, rayHeight, false)
  let paraxialD = traceLine(4, rayHeight, true)
  let marginalC = traceLine(3, rayHeight, false).objectDistance
  let marginalF = traceLine(6, rayHeight, false).objectDistance
  let sphericalAberration = paraxialD.objectDistance - marginalD.objectDistance
  let sineConditionAberration = 1.0 - (paraxialD.objectDistance * paraxialD.axisSlopeAngle)
    / (sin(marginalD.axisSlopeAngle) * marginalD.objectDistance)
  let chromaticAberration = marginalF - marginalC
  sphericalAberration + sineConditionAberration + chromaticAberration

proc freebench_fbench*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "freebench_fbench".} =
  if values.isNil or length != csize_t(1) or values[0] < 1 or values[0] > MaxPasses:
    return InvalidResult
  var total = 0.0
  for pass in 0 ..< int(values[0]):
    let rayHeight = 2.0 + 0.0002 * float64(pass)
    total += onePassProjection(rayHeight)
  total
