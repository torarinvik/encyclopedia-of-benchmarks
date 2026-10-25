import std/math

const PatternCount = 10
const MaxNeurons = 8
const MaxInputLength = 94

proc activation(value: float32): float32 =
  var x = float64(value)
  if x > 200.0: x = 200.0
  if x < -200.0: x = -200.0
  let e = exp(-x)
  float32((1.0 - e) / (1.0 + e))

proc runCont(weights: ptr UncheckedArray[float32], source: ptr UncheckedArray[int64], neurons: int,
             dest: ptr UncheckedArray[int64]): bool =
  var tempA: array[MaxNeurons, float32]
  var tempC: array[MaxNeurons, int64]
  for neuron in 0 ..< neurons:
    dest[neuron] = source[neuron]
    tempA[neuron] = float32(source[neuron])
  var stable = false
  var threshold = false
  var iterations = 0
  while not stable and iterations < 500:
    var thresholdIterations = 0
    for row in 0 ..< neurons:
      var sum = 0.0'f32
      for neuron in 0 ..< neurons: sum += weights[row * neurons + neuron] * float32(source[neuron])
      tempA[row] = activation(sum)
    while not threshold and thresholdIterations < 50:
      threshold = true
      for row in 0 ..< neurons:
        if abs(float64(tempA[row])) < 0.7:
          var sum = 0.0'f32
          for neuron in 0 ..< neurons: sum += weights[row * neurons + neuron] * tempA[neuron]
          tempA[row] = activation(sum)
          if tempA[row] < 0.7'f32: threshold = false
      inc thresholdIterations
    var same = true
    for neuron in 0 ..< neurons:
      tempC[neuron] = if tempA[neuron] > 0.0'f32: 1 else: -1
      if dest[neuron] != tempC[neuron]: same = false
    if same:
      stable = true
    else:
      for neuron in 0 ..< neurons:
        if dest[neuron] != tempC[neuron]:
          dest[neuron] = tempC[neuron]
          break
      for neuron in 0 ..< neurons: tempA[neuron] = float32(dest[neuron])
    inc iterations
  iterations < 500

proc freebench_neural_hopfield*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "freebench_neural_hopfield".} =
  if input == nil or length < 3 or length > MaxInputLength: return -1
  let width = input[0]
  let height = input[1]
  let patternCount = input[2]
  if width < 1 or width > 8 or height < 1 or height > 8 or patternCount != PatternCount: return -1
  let neurons = int(width * height)
  if neurons < 2 or neurons > MaxNeurons or length != csize_t(3 + PatternCount * (1 + neurons)): return -1

  var patterns: array[PatternCount * MaxNeurons, int64]
  var offset = 3
  for pattern in 0 ..< PatternCount:
    let label = input[offset]
    inc offset
    if label < 65 or label > 90: return -1
    for neuron in 0 ..< neurons:
      let cell = input[offset]
      inc offset
      if cell != -1 and cell != 1: return -1
      patterns[pattern * MaxNeurons + neuron] = cell
      if pattern != 0 and cell != patterns[neuron]: return -1

  var hammingWarnings = 0
  for first in 0 ..< PatternCount:
    for second in first + 1 ..< PatternCount:
      var normal = 0
      var complement = 0
      for neuron in 0 ..< neurons:
        if patterns[first * MaxNeurons + neuron] != patterns[second * MaxNeurons + neuron]: inc normal
        if patterns[first * MaxNeurons + neuron] != -patterns[second * MaxNeurons + neuron]: inc complement
      if normal < 2: inc hammingWarnings
      if complement < 2: inc hammingWarnings
  discard hammingWarnings

  var weights: array[MaxNeurons * MaxNeurons, float32]
  for pattern in 0 ..< PatternCount:
    for row in 0 ..< neurons:
      for column in 0 ..< neurons:
        if row == column: weights[row * neurons + column] = 0.0'f32
        else: weights[row * neurons + column] += float32(patterns[pattern * MaxNeurons + row] * patterns[pattern * MaxNeurons + column])

  var converged = false
  for _pass in 0 ..< 1:
    var status = true
    for pattern in 0 ..< PatternCount:
      var recalled: array[MaxNeurons, int64]
      let weightsPtr = cast[ptr UncheckedArray[float32]](addr weights[0])
      let sourcePtr = cast[ptr UncheckedArray[int64]](addr patterns[pattern * MaxNeurons])
      let recalledPtr = cast[ptr UncheckedArray[int64]](addr recalled[0])
      if not runCont(weightsPtr, sourcePtr, neurons, recalledPtr): return -2
      var correction: array[MaxNeurons, float32]
      for neuron in 0 ..< neurons:
        correction[neuron] = float32(patterns[pattern * MaxNeurons + neuron] - recalled[neuron]) * 0.5'f32
        if correction[neuron] != 0.0'f32: status = false
      for row in 0 ..< neurons:
        for column in 0 ..< neurons:
          if row == column: weights[row * neurons + column] = 0.0'f32
          else: weights[row * neurons + column] += correction[row] * float32(patterns[pattern * MaxNeurons + column])
    if status: converged = true
  if not converged: return -2

  var storedCount = 0'i64
  for pattern in 0 ..< PatternCount:
    var recalled: array[MaxNeurons, int64]
    let weightsPtr = cast[ptr UncheckedArray[float32]](addr weights[0])
    let sourcePtr = cast[ptr UncheckedArray[int64]](addr patterns[pattern * MaxNeurons])
    let recalledPtr = cast[ptr UncheckedArray[int64]](addr recalled[0])
    if not runCont(weightsPtr, sourcePtr, neurons, recalledPtr): return -2
    var stored = true
    for neuron in 0 ..< neurons:
      if patterns[pattern * MaxNeurons + neuron] != recalled[neuron]: stored = false
    if stored: inc storedCount
  storedCount
