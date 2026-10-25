## Copyright (c) 2014 John Tramm
##
## Permission is hereby granted, free of charge, to any person obtaining a copy
## of this software and associated documentation files (the "Software"), to deal
## in the Software without restriction, including without limitation the rights
## to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
## copies of the Software, and to permit persons to whom the Software is
## furnished to do so, subject to the following conditions:
##
## The above copyright notice and this permission notice shall be included in all
## copies or substantial portions of the Software.
##
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
## IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
## FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
## AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
## LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
## OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
## SOFTWARE.
##
## Bounded source-shaped profile of SimpleMOC solver.c::attenuate_fluxes.

import std/math

const InvalidResult = -1.0e300
const FixedScale = 1_000_000'f32
const MaxRaw = 10_000_000'i64
const MaxGroups = 4'i64
const TableSize = 353'f32

proc add32(a, b: float32): float32 = float32(a + b)
proc sub32(a, b: float32): float32 = float32(a - b)
proc mul32(a, b: float32): float32 = float32(a * b)
proc div32(a, b: float32): float32 = float32(a / b)
proc fixed(raw: int64): float32 = div32(float32(raw), FixedScale)

proc expTable(tau: float32): float32 =
  let dx = div32(10.0'f32, TableSize)
  let maxValue = sub32(10.0'f32, dx)
  if tau > maxValue: return 1.0'f32
  let roundedIndex = add32(div32(tau, dx), mul32(0.5'f32, dx))
  let interval = int(roundedIndex)
  let anchor = mul32(float32(interval), dx)
  let e = float32(exp(-float64(anchor)))
  let slope = -e
  let anchorOffset = sub32(anchor, 1.0'f32)
  let interceptProduct = mul32(anchorOffset, e)
  let intercept = add32(1.0'f32, interceptProduct)
  add32(mul32(slope, tau), intercept)

proc doe_simplemoc_quadratic_attenuation*(input: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "doe_simplemoc_quadratic_attenuation".} =
  if input == nil or length < 13 or length > 31: return InvalidResult
  let groupsRaw = input[0]
  if groupsRaw < 1 or groupsRaw > MaxGroups: return InvalidResult
  let groups = int(groupsRaw)
  if int(length) != 7 + 6 * groups: return InvalidResult

  for index in 1 ..< int(length):
    if input[index] < -MaxRaw or input[index] > MaxRaw: return InvalidResult

  let zinRaw = input[1]
  let dzRaw = input[2]
  let dsRaw = input[3]
  let muRaw = input[4]
  let azWeightRaw = input[5]
  let polarWeightRaw = input[6]
  if dzRaw < 10_000 or dsRaw < 1_000 or muRaw < 0 or muRaw > 1_000_000 or
      azWeightRaw < 0 or azWeightRaw > 1_000_000 or
      polarWeightRaw < 0 or polarWeightRaw > 1_000_000:
    return InvalidResult

  let zin = fixed(zinRaw)
  let dz = fixed(dzRaw)
  let ds = fixed(dsRaw)
  let mu = fixed(muRaw)
  let azWeight = fixed(azWeightRaw)
  let polarWeight = fixed(polarWeightRaw)
  let twiceZin = mul32(2.0'f32, zin)
  if abs(twiceZin) > dz: return InvalidResult
  let weight = mul32(polarWeight, azWeight)
  var checksum = 0.0'f32

  for group in 0 ..< groups:
    let base = 7 + 6 * group
    let previousRaw = input[base]
    let centerRaw = input[base + 1]
    let nextRaw = input[base + 2]
    let sigmaRaw = input[base + 3]
    let psiRaw = input[base + 4]
    let tallyRaw = input[base + 5]
    if sigmaRaw < 100_000 or psiRaw < 0 or tallyRaw < 0: return InvalidResult

    let previous = fixed(previousRaw)
    let center = fixed(centerRaw)
    let next = fixed(nextRaw)
    let sigma = fixed(sigmaRaw)
    let psi = fixed(psiRaw)
    let tally = fixed(tallyRaw)

    let twiceDz = mul32(2.0'f32, dz)
    let c1 = div32(sub32(previous, next), twiceDz)
    let twiceCenter = mul32(2.0'f32, center)
    let c2Numerator = add32(sub32(previous, twiceCenter), next)
    let c2Denominator = mul32(twiceDz, dz)
    let c2 = div32(c2Numerator, c2Denominator)

    let q0Linear = mul32(c1, zin)
    let q0QuadraticFirst = mul32(c2, zin)
    let q0Quadratic = mul32(q0QuadraticFirst, zin)
    let q0 = add32(add32(center, q0Linear), q0Quadratic)
    let q1Curve = mul32(2.0'f32, c2)
    let q1 = add32(c1, mul32(q1Curve, zin))
    let q2 = c2

    let tau = mul32(sigma, ds)
    if tau <= 0.0'f32 or tau > 10.0'f32: return InvalidResult
    let expValue = expTable(tau)
    let sigmaSquared = mul32(sigma, sigma)
    let reuseNumerator = mul32(2.0'f32, expValue)
    let reuseDenominator = mul32(sigma, sigmaSquared)
    let reuseQuotient = div32(reuseNumerator, reuseDenominator)
    let reusePolynomial = mul32(tau, sub32(tau, 2.0'f32))
    let reuse = add32(reusePolynomial, reuseQuotient)

    let q0Tau = mul32(q0, tau)
    let sigmaPsi = mul32(sigma, psi)
    let difference = sub32(sigmaPsi, q0)
    let differenceExp = mul32(difference, expValue)
    let integralFirst = div32(add32(q0Tau, differenceExp), sigmaSquared)
    let integralSecond = mul32(mul32(q1, mu), reuse)

    let muSquared = mul32(mu, mu)
    let tauMinusThree = sub32(tau, 3.0'f32)
    let tauInner = add32(mul32(tau, tauMinusThree), 6.0'f32)
    let tauOuter = mul32(tau, tauInner)
    let sixExp = mul32(6.0'f32, expValue)
    let integralPolynomial = sub32(tauOuter, sixExp)
    let integralDenominator = mul32(mul32(3.0'f32, sigmaSquared), sigmaSquared)
    let integralThird = div32(
      mul32(mul32(q2, muSquared), integralPolynomial), integralDenominator)
    let fluxIntegral = add32(add32(integralFirst, integralSecond), integralThird)
    let tallyDelta = mul32(weight, fluxIntegral)
    let tallyOut = add32(tally, tallyDelta)

    let term1 = div32(mul32(q0, expValue), sigma)
    let term2Numerator = mul32(mul32(q1, mu), sub32(tau, expValue))
    let term2 = div32(term2Numerator, sigmaSquared)
    let term3 = mul32(mul32(q2, muSquared), reuse)
    let term4 = mul32(psi, sub32(1.0'f32, expValue))
    let psiOut = add32(add32(add32(term1, term2), term3), term4)

    let groupTotal = add32(tallyOut, psiOut)
    let weightedTotal = mul32(float32(group + 1), groupTotal)
    checksum = add32(checksum, weightedTotal)

  float64(checksum)
