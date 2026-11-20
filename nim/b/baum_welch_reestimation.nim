import std/math

const MaxInput = 48
const MaxOutput = 36
const MinProbability = 0.001
const RowTolerance = 1e-9

proc exactInteger(value: float64, low, high: int): bool =
  value.classify notin {fcNan, fcInf, fcNegInf} and value >= float64(low) and
    value <= float64(high) and value == float64(int(value))

proc validRow(values: ptr UncheckedArray[float64], start, count: int): bool =
  var total = 0.0
  for i in 0 ..< count:
    let value = values[start + i]
    if value.classify in {fcNan, fcInf, fcNegInf} or value < MinProbability or value > 1.0: return false
    total += value
  abs(total - 1.0) <= RowTolerance

proc baum_welch_reestimation*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "baum_welch_reestimation".} =
  if input.isNil or inputLength < 3 or inputLength > MaxInput.csize_t: return -1
  if not exactInteger(input[0], 2, 4) or not exactInteger(input[1], 2, 4) or not exactInteger(input[2], 1, 8): return -1
  let states = int(input[0])
  let symbols = int(input[1])
  let timeCount = int(input[2])
  if int(inputLength) != 3 + states + states * states + states * symbols + timeCount: return -1

  var initial: array[4, float64]
  var transition: array[16, float64]
  var emission: array[16, float64]
  var observations: array[8, int]
  var cursor = 3
  for i in 0 ..< states: initial[i] = input[cursor + i]
  cursor += states
  for i in 0 ..< states * states: transition[i] = input[cursor + i]
  cursor += states * states
  for i in 0 ..< states * symbols: emission[i] = input[cursor + i]
  cursor += states * symbols
  if not validRow(cast[ptr UncheckedArray[float64]](addr initial[0]), 0, states): return -1
  for state in 0 ..< states:
    if not validRow(cast[ptr UncheckedArray[float64]](addr transition[0]), state * states, states) or
        not validRow(cast[ptr UncheckedArray[float64]](addr emission[0]), state * symbols, symbols): return -1
  for time in 0 ..< timeCount:
    if not exactInteger(input[cursor + time], 0, symbols - 1): return -1
    observations[time] = int(input[cursor + time])

  var alpha: array[32, float64]
  var beta: array[32, float64]
  var gamma: array[32, float64]
  var staged: array[MaxOutput, float64]
  for state in 0 ..< states: alpha[state] = initial[state] * emission[state * symbols + observations[0]]
  for time in 1 ..< timeCount:
    for destination in 0 ..< states:
      var incoming = 0.0
      for source in 0 ..< states: incoming += alpha[(time - 1) * states + source] * transition[source * states + destination]
      alpha[time * states + destination] = incoming * emission[destination * symbols + observations[time]]
  var likelihood = 0.0
  for state in 0 ..< states: likelihood += alpha[(timeCount - 1) * states + state]
  for state in 0 ..< states: beta[(timeCount - 1) * states + state] = 1.0
  var time = timeCount - 1
  while time > 0:
    dec time
    for source in 0 ..< states:
      var total = 0.0
      for destination in 0 ..< states:
        total += transition[source * states + destination] * emission[destination * symbols + observations[time + 1]] * beta[(time + 1) * states + destination]
      beta[time * states + source] = total
  for t in 0 ..< timeCount:
    for state in 0 ..< states: gamma[t * states + state] = alpha[t * states + state] * beta[t * states + state] / likelihood

  let outputCount = states + states * states + states * symbols
  var out = 0
  for state in 0 ..< states:
    staged[out] = gamma[state]
    inc out
  if timeCount == 1:
    for i in 0 ..< states * states:
      staged[out] = transition[i]
      inc out
  else:
    for source in 0 ..< states:
      var denominator = 0.0
      for t in 0 ..< timeCount - 1: denominator += gamma[t * states + source]
      for destination in 0 ..< states:
        var count = 0.0
        for t in 0 ..< timeCount - 1:
          count += alpha[t * states + source] * transition[source * states + destination] * emission[destination * symbols + observations[t + 1]] * beta[(t + 1) * states + destination] / likelihood
        staged[out] = count / denominator
        inc out
  for state in 0 ..< states:
    var denominator = 0.0
    for t in 0 ..< timeCount: denominator += gamma[t * states + state]
    for symbol in 0 ..< symbols:
      var count = 0.0
      for t in 0 ..< timeCount:
        if observations[t] == symbol: count += gamma[t * states + state]
      staged[out] = count / denominator
      inc out
  if out != outputCount: return -1
  if output.isNil or outputCapacity < csize_t(outputCount): return -2
  for i in 0 ..< outputCount: output[i] = staged[i]
  int64(outputCount)
