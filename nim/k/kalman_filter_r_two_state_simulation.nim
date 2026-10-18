import std/math

const
  MaxObservations = 12
  MaxOutputElements = 30

proc kalman_filter_r_two_state_simulation*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "kalman_filter_r_two_state_simulation".} =
  if input == nil or inputLength < 1 or inputLength > MaxObservations.csize_t: return -1
  let observationCount = int(inputLength)
  for index in 0 ..< observationCount:
    let value = input[index]
    let valueClass = classify(value)
    if valueClass == fcNan or valueClass == fcInf or valueClass == fcNegInf or
        value < -1000.0 or value > 1000.0: return -1

  let required = 2 * observationCount + 6
  if required > MaxOutputElements: return -1
  var staged: array[MaxOutputElements, float64]
  var state0 = input[0]
  var state1 = 0.0
  var covariance00 = 1.0
  var covariance01 = 0.0
  var covariance10 = 0.0
  var covariance11 = 1.0
  var statePred0 = 0.0
  var statePred1 = 0.0
  var covariancePred00 = 0.0
  var covariancePred01 = 0.0
  var covariancePred10 = 0.0
  var covariancePred11 = 0.0

  for step in 0 ..< observationCount:
    statePred0 = state0
    statePred1 = state0 + state1

    let temp00 = covariance00
    let temp01 = covariance01
    let temp10 = covariance00 + covariance10
    let temp11 = covariance01 + covariance11
    covariancePred00 = temp00 + 0.0001
    covariancePred01 = temp00 + temp01
    covariancePred10 = temp10
    covariancePred11 = temp10 + temp11 + 0.0001

    let innovation = covariancePred00 + 0.1
    let gain0 = covariancePred00 / innovation
    let gain1 = covariancePred10 / innovation
    let residual = input[step] - statePred0
    state0 = statePred0 + gain0 * residual
    state1 = statePred1 + gain1 * residual
    staged[2 * step] = state0
    staged[2 * step + 1] = state1

    covariance00 = (1.0 - gain0) * covariancePred00 + covariancePred10
    covariance01 = (1.0 - gain0) * covariancePred01 + covariancePred11
    covariance10 = (1.0 - gain1) * covariancePred00 + covariancePred10
    covariance11 = (1.0 - gain1) * covariancePred01 + covariancePred11

  var position = 2 * observationCount
  staged[position] = statePred0
  staged[position + 1] = statePred1
  staged[position + 2] = covariancePred00
  staged[position + 3] = covariancePred10
  staged[position + 4] = covariancePred01
  staged[position + 5] = covariancePred11
  if output == nil or outputCapacity < required.csize_t: return -2
  for index in 0 ..< required: output[index] = staged[index]
  int64(required)
