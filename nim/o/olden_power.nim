import std/math

const MaxLeaves = 4
const MaxPasses = 4
const GEpsilon = 0.000001
const HEpsilon = 0.000001

proc findG(p, q: float64): float64 = p * p + q * q - 0.8
proc findH(p, q: float64): float64 = p - 5.0 * q

proc gradientF(p, q, piR, piI: float64, gradient: var array[2, float64]): float64 =
  gradient[0] = 1.0 / (1.0 + p) - piR
  gradient[1] = 1.0 / (1.0 + q) - piI
  let magnitude = sqrt(gradient[0] * gradient[0] + gradient[1] * gradient[1])
  gradient[0] /= magnitude
  gradient[1] /= magnitude
  magnitude

proc gradientG(p, q: float64, gradient: var array[2, float64]): float64 =
  gradient[0] = 2.0 * p
  gradient[1] = 2.0 * q
  let magnitude = sqrt(gradient[0] * gradient[0] + gradient[1] * gradient[1])
  gradient[0] /= magnitude
  gradient[1] /= magnitude
  magnitude

proc gradientH(gradient: var array[2, float64]): float64 =
  let magnitude = sqrt(26.0)
  gradient[0] = 1.0 / magnitude
  gradient[1] = -5.0 / magnitude
  magnitude

proc secondGradientF(p, q, piR, piI: float64, result: var array[2, float64]) =
  let pInv = 1.0 / (p + 1.0)
  let qInv = 1.0 / (q + 1.0)
  let pTerm = pInv - piR
  let qTerm = qInv - piI
  let magnitude = sqrt(pTerm * pTerm + qTerm * qTerm)
  result[0] = -pInv * pInv * pTerm / magnitude
  result[1] = -qInv * qInv * qTerm / magnitude

proc makeOrthogonal(modified: var array[2, float64], fixed: array[2, float64]): float64 =
  let dot = modified[0] * fixed[0] + modified[1] * fixed[1]
  modified[0] -= dot * fixed[0]
  modified[1] -= dot * fixed[1]
  let length = sqrt(modified[0] * modified[0] + modified[1] * modified[1])
  modified[0] /= length
  modified[1] /= length
  if 1.0 - dot * dot < 0.0: return 0.0
  sqrt(1.0 - dot * dot)

proc optimizeOne(p, q: var float64, piR, piI: float64) =
  var gradF, gradG, gradH, ddGradF: array[2, float64]
  let h = findH(p, q)
  if abs(h) > HEpsilon:
    let magnitude = gradientH(gradH)
    let total = h / magnitude
    p -= total * gradH[0]
    q -= total * gradH[1]
  let g = findG(p, q)
  if g > GEpsilon:
    var magnitude = gradientG(p, q, gradG)
    discard gradientH(gradH)
    magnitude *= makeOrthogonal(gradG, gradH)
    let total = g / magnitude
    p -= total * gradG[0]
    q -= total * gradG[1]
  var magnitude = gradientF(p, q, piR, piI, gradF)
  secondGradientF(p, q, piR, piI, ddGradF)
  var total = gradF[0] * ddGradF[0] + gradF[1] * ddGradF[1]
  magnitude /= abs(total)
  discard gradientH(gradH)
  magnitude *= makeOrthogonal(gradF, gradH)
  discard gradientG(p, q, gradG)
  total = gradF[0] * gradG[0] + gradF[1] * gradG[1]
  if total > 0.0:
    let maxDist = -findG(p, q) / total
    if magnitude > maxDist: magnitude = maxDist
  p += magnitude * gradF[0]
  q += magnitude * gradF[1]

proc solveVoltage(p, q: var float64, resistance, reactance: float64,
                  alpha, beta: var float64) =
  var a = resistance * resistance + reactance * reactance
  var b = 2.0 * resistance * reactance * q - 2.0 * reactance * reactance * p - resistance
  var c = resistance * q - reactance * p
  c = c * c + resistance * p
  let root = (-b - sqrt(b * b - 4.0 * a * c)) / (2.0 * a)
  q += ((root - p) * reactance) / resistance
  p = root
  a = 2.0 * resistance * p
  b = 2.0 * reactance * q
  alpha = a / (1.0 - a - b)
  beta = b / (1.0 - a - b)

proc olden_power*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "olden_power".} =
  if input == nil or length != 2: return -1
  let leavesValue = input[0]
  let passesValue = input[1]
  if leavesValue < 1 or leavesValue > MaxLeaves or passesValue < 0 or passesValue > MaxPasses: return -1
  let leaves = int(leavesValue)
  let passes = int(passesValue)
  var leafP: array[MaxLeaves, float64]
  var leafQ: array[MaxLeaves, float64]
  for i in 0 ..< MaxLeaves:
    leafP[i] = 1.0
    leafQ[i] = 1.0
  var branchAlpha = 0.0
  var branchBeta = 0.0
  var lateralAlpha = 0.0
  var lateralBeta = 0.0
  const thetaR = 0.8
  const thetaI = 0.16
  var workCount: int64 = 0
  for _ in 0 ..< passes:
    let lateralPiR = thetaR + lateralAlpha * (thetaR + (thetaI * 0.000001) / (1.0 / 300000.0))
    let lateralPiI = thetaI + lateralBeta * (thetaI + (thetaR * (1.0 / 300000.0)) / 0.000001)
    let branchPiR = lateralPiR + branchAlpha * (thetaR + (thetaI * 0.00002) / 0.0001)
    let branchPiI = lateralPiI + branchBeta * (thetaI + (thetaR * 0.0001) / 0.00002)
    var branchP = 0.0
    var branchQ = 0.0
    for leaf in 0 ..< leaves:
      optimizeOne(leafP[leaf], leafQ[leaf], branchPiR, branchPiI)
      if leafP[leaf] < 0.0:
        leafP[leaf] = 0.0
        leafQ[leaf] = 0.0
      branchP += leafP[leaf]
      branchQ += leafQ[leaf]
      inc workCount
    solveVoltage(branchP, branchQ, 0.0001, 0.00002, branchAlpha, branchBeta)
    var lateralP = branchP
    var lateralQ = branchQ
    solveVoltage(lateralP, lateralQ, 1.0 / 300000.0, 0.000001, lateralAlpha, lateralBeta)
  var stateProjection: int64 = 0
  for leaf in 0 ..< leaves:
    stateProjection += int64(floor(leafP[leaf] * 1000.0 + 0.5))
    stateProjection += 2 * int64(floor(leafQ[leaf] * 1000.0 + 0.5))
  stateProjection += int64(floor(branchAlpha * 1000.0 + 0.5))
  stateProjection += 2 * int64(floor(branchBeta * 1000.0 + 0.5))
  stateProjection += int64(floor(lateralAlpha * 1000.0 + 0.5))
  stateProjection += 2 * int64(floor(lateralBeta * 1000.0 + 0.5))
  stateProjection + workCount
