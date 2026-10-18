import std/math

const MaxParseableInputLength = 11

proc exactInteger(value: float64, minimum, maximum: int64): bool =
  if classify(value) in {fcNan, fcInf, fcNegInf}: return false
  if value < float64(minimum) or value > float64(maximum): return false
  float64(int64(value)) == value

proc qLearningUpdate*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "q_learning_update".} =
  if input == nil or inputLength < 6 or inputLength > MaxParseableInputLength.csize_t: return -1
  if not exactInteger(input[0], 0, 1) or not exactInteger(input[5], 0, 4): return -1
  let done = input[0] == 1.0
  let alpha, gamma, reward, oldQ = input[1], input[2], input[3], input[4]
  let nextActionCount = int(input[5])
  if inputLength != csize_t(6 + nextActionCount): return -1
  if classify(alpha) in {fcNan, fcInf, fcNegInf} or alpha < 0.0 or alpha > 1.0: return -1
  if classify(gamma) in {fcNan, fcInf, fcNegInf} or gamma < 0.0 or gamma > 1.0: return -1
  if classify(reward) in {fcNan, fcInf, fcNegInf} or reward < -100.0 or reward > 100.0: return -1
  if classify(oldQ) in {fcNan, fcInf, fcNegInf} or oldQ < -100.0 or oldQ > 100.0: return -1
  for index in 0 ..< nextActionCount:
    let value = input[6 + index]
    if classify(value) in {fcNan, fcInf, fcNegInf} or value < -100.0 or value > 100.0: return -1

  var maxQNext = 0.0
  if not done and nextActionCount > 0:
    maxQNext = input[6]
    for index in 1 ..< nextActionCount:
      if input[6 + index] > maxQNext: maxQNext = input[6 + index]
  let updated = (1.0 - alpha) * oldQ + alpha * (reward + gamma * maxQNext)
  if classify(updated) in {fcNan, fcInf, fcNegInf}: return -1
  if output == nil or capacity < 1: return -2
  output[0] = updated
  1
