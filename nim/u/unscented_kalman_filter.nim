import std/math

const Bad = -1.0e300
const Scale = 1000.0

proc sigmaPoints(x, y, p00, p01, p11: float64; points: var array[5, array[2, float64]]): bool =
  let l00 = sqrt(2.0 * p00)
  if l00 <= 0.0: return false
  let l10 = (2.0 * p01) / l00
  let remainder = 2.0 * p11 - l10 * l10
  if remainder <= 0.0: return false
  let l11 = sqrt(remainder)
  points[0] = [x, y]
  points[1] = [x + l00, y + l10]
  points[2] = [x, y + l11]
  points[3] = [x - l00, y - l10]
  points[4] = [x, y - l11]
  true

proc unscented_kalman_filter*(v: ptr UncheckedArray[int64], n: csize_t): float64 {.cdecl, exportc: "unscented_kalman_filter".} =
  if v.isNil or n < 10 or n > 17: return Bad
  let steps = v[0]
  if steps < 1 or steps > 8 or n != csize_t(9 + steps): return Bad
  if v[1] < -1000 or v[1] > 1000 or v[2] < -1000 or v[2] > 1000: return Bad
  if v[3] < 500 or v[3] > 1000 or v[4] < -100 or v[4] > 100 or v[5] < 500 or v[5] > 1000: return Bad
  if v[6] < 10 or v[6] > 50 or v[7] < 10 or v[7] > 50 or v[8] < 10 or v[8] > 100: return Bad
  for i in 9 ..< int(n):
    if v[i] < -2000 or v[i] > 2000: return Bad

  var x = float64(v[1]) / Scale
  var y = float64(v[2]) / Scale
  var p00 = float64(v[3]) / Scale
  var p01 = float64(v[4]) / Scale
  var p11 = float64(v[5]) / Scale
  let q0 = float64(v[6]) / Scale
  let q1 = float64(v[7]) / Scale
  let noise = float64(v[8]) / Scale
  for t in 0 ..< int(steps):
    var sigma: array[5, array[2, float64]]
    if not sigmaPoints(x, y, p00, p01, p11, sigma): return Bad
    var propagated: array[5, array[2, float64]]
    for i in 0 ..< 5:
      let sx = sigma[i][0]
      let sy = sigma[i][1]
      propagated[i][0] = sx + 0.1 * sy
      propagated[i][1] = sy + 0.05 * sx * sx
    var meanX = 0.0
    var meanY = 0.0
    for i in 1 ..< 5:
      meanX += 0.25 * propagated[i][0]
      meanY += 0.25 * propagated[i][1]
    var nextP00 = 2.0 * (propagated[0][0] - meanX) * (propagated[0][0] - meanX)
    var nextP01 = 2.0 * (propagated[0][0] - meanX) * (propagated[0][1] - meanY)
    var nextP11 = 2.0 * (propagated[0][1] - meanY) * (propagated[0][1] - meanY)
    for i in 1 ..< 5:
      let dx = propagated[i][0] - meanX
      let dy = propagated[i][1] - meanY
      nextP00 += 0.25 * dx * dx
      nextP01 += 0.25 * dx * dy
      nextP11 += 0.25 * dy * dy
    x = meanX
    y = meanY
    p00 = nextP00 + q0
    p01 = 0.5 * (nextP01 + nextP01)
    p11 = nextP11 + q1

    if not sigmaPoints(x, y, p00, p01, p11, sigma): return Bad
    var mapped: array[5, float64]
    for i in 0 ..< 5:
      mapped[i] = 0.05 * sigma[i][0] * sigma[i][0] + sigma[i][1]
    var expectedZ = 0.0
    for i in 1 ..< 5: expectedZ += 0.25 * mapped[i]
    var innovation = noise
    var cross0 = 0.0
    var cross1 = 0.0
    for i in 0 ..< 5:
      let weight = if i == 0: 2.0 else: 0.25
      let dx = sigma[i][0] - x
      let dy = sigma[i][1] - y
      let dz = mapped[i] - expectedZ
      innovation += weight * dz * dz
      cross0 += weight * dx * dz
      cross1 += weight * dy * dz
    if innovation <= 0.0: return Bad
    let k0 = cross0 / innovation
    let k1 = cross1 / innovation
    let residual = float64(v[9 + t]) / Scale - expectedZ
    x += k0 * residual
    y += k1 * residual
    let u0 = k0 * innovation
    let u1 = k1 * innovation
    let oldP01 = p01
    p00 -= u0 * k0
    p01 = oldP01 - 0.5 * (u0 * k1 + u1 * k0)
    p11 -= u1 * k1
  x
