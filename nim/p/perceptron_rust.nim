import math

const Mode = 3
const MaxOutput = 25

proc finite(x: float64): bool = classify(x) notin {fcNan, fcInf, fcNegInf}

proc perceptron_impl(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64 =
  if input == nil or inputLength < 9 or inputLength > 62: return -1
  for i in 0 ..< int(inputLength):
    if not finite(input[i]): return -1
  var rate: float64
  var epochs: int
  var samples: int
  var features: int
  if Mode == 3:
    if input[0] != floor(input[0]) or input[0] < 0 or input[0] > 12: return -1
    epochs = int(input[0]); rate = input[1]
  else:
    rate = input[0]
    if input[1] != floor(input[1]) or input[1] < 1 or input[1] > 12: return -1
    epochs = int(input[1])
  if rate notin {0.25, 0.5, 0.75, 1.0}: return -1
  if input[2] != floor(input[2]) or input[2] < 2 or input[2] > 8: return -1
  samples = int(input[2])
  if input[3] != floor(input[3]) or input[3] < 1 or input[3] > 4: return -1
  features = int(input[3])
  let featureStart = 4
  let labelsStart = featureStart + samples * features
  let qIndex = labelsStart + samples
  if int(inputLength) <= qIndex or input[qIndex] != floor(input[qIndex]) or input[qIndex] < 1 or input[qIndex] > 4: return -1
  let queries = int(input[qIndex])
  let queryStart = qIndex + 1
  if int(inputLength) != queryStart + queries * features or inputLength > 61: return -1
  for i in 0 ..< samples * features:
    let v = input[featureStart + i]
    if v != floor(v) or v < -2 or v > 2: return -1
  for i in 0 ..< queries * features:
    let v = input[queryStart + i]
    if v != floor(v) or v < -2 or v > 2: return -1
  var labels: array[8, int]
  var classes: array[3, int]
  var classCount = 0
  for i in 0 ..< samples:
    let v = input[labelsStart + i]
    if v != floor(v): return -1
    if Mode == 0 and v notin {0.0, 1.0}: return -1
    if (Mode == 1 or Mode == 3) and v notin {-1.0, 1.0}: return -1
    if Mode == 2 and (v < -2 or v > 2): return -1
    labels[i] = int(v)
    if Mode == 2:
      var found = false
      for c in 0 ..< classCount:
        if classes[c] == int(v): found = true
      if not found:
        if classCount >= 3: return -1
        classes[classCount] = int(v)
        classCount += 1
  if Mode == 2:
    if classCount < 2: return -1
    for i in 0 ..< classCount:
      for j in i + 1 ..< classCount:
        if classes[j] < classes[i]: swap(classes[i], classes[j])
  else:
    classCount = 2

  var weights: array[15, float64]
  var epochsRun = 0
  var converged = false
  if Mode == 1:
    weights[0] = -1.0
    let seeded = [0.8444218515250481, 0.7579544029403025, 0.420571580830845, 0.25891675029296335]
    for j in 0 ..< features: weights[j + 1] = seeded[j]
  if Mode == 0 or Mode == 1:
    for epoch in 0 ..< epochs:
      var updated = false
      for row in 0 ..< samples:
        var score = 0.0
        if Mode == 0: score = weights[features]
        for col in 0 ..< features:
          let x = input[featureStart + row * features + col]
          if Mode == 1:
            if col == 0: score += weights[0] * -1.0
            score += weights[col + 1] * x
          else: score += weights[col] * x
        let pred = if Mode == 0: (if score >= 0: 1 else: 0) else: (if score >= 0: 1 else: -1)
        let error = labels[row] - pred
        if error != 0:
          if Mode == 0:
            for col in 0 ..< features:
              let x = input[featureStart + row * features + col]
              weights[col] += rate * float64(error) * x
            weights[features] += rate * float64(error)
          else:
            weights[0] += rate * float64(error) * -1.0
            for col in 0 ..< features:
              weights[col + 1] += rate * float64(error) * input[featureStart + row * features + col]
          updated = true
      epochsRun = epoch + 1
      if Mode == 0 and not updated: converged = true; break
      if Mode == 1 and not updated: break
  elif Mode == 3:
    for epoch in 0 ..< epochs:
      var misses = 0
      for row in 0 ..< samples:
        var score = 0.0
        for col in 0 ..< features: score += weights[col] * input[featureStart + row * features + col]
        score += weights[features]
        let pred = if score >= 0: 1 else: -1
        if pred != labels[row]:
          misses += 1
          for col in 0 ..< features: weights[col] += rate * float64(labels[row]) * input[featureStart + row * features + col]
          weights[features] += rate * float64(labels[row])
      if misses == 0: break
  else:
    let stride = features + 1
    for epoch in 0 ..< epochs:
      for row in 0 ..< samples:
        if classCount == 2:
          let label = if labels[row] == classes[0]: -1 else: 1
          var score = 0.0
          score += weights[0]
          for col in 0 ..< features: score += weights[col + 1] * input[featureStart + row * features + col]
          if float64(label) * score <= 0:
            weights[0] += rate * float64(label)
            for col in 0 ..< features: weights[col + 1] += rate * float64(label) * input[featureStart + row * features + col]
        else:
          var predicted = 0
          var best = 0.0
          for c in 0 ..< classCount:
            var score = weights[c * stride]
            for col in 0 ..< features: score += weights[c * stride + col + 1] * input[featureStart + row * features + col]
            if c == 0 or score > best: best = score; predicted = c
          var target = 0
          for c in 0 ..< classCount:
            if classes[c] == labels[row]: target = c
          if predicted != target:
            weights[target * stride] += rate
            weights[predicted * stride] -= rate
            for col in 0 ..< features:
              let x = input[featureStart + row * features + col]
              weights[target * stride + col + 1] += rate * x
              weights[predicted * stride + col + 1] -= rate * x

  var staged: array[MaxOutput, float64]
  var outN = 0
  if Mode == 0:
    staged[0] = float64(features)
    for col in 0 ..< features: staged[1 + col] = weights[col]
    staged[1 + features] = weights[features]
    staged[2 + features] = float64(epochsRun)
    staged[3 + features] = if converged: 1.0 else: 0.0
    staged[4 + features] = float64(queries)
    outN = 5 + features
  elif Mode == 1:
    staged[0] = float64(epochsRun); staged[1] = float64(features + 1)
    for j in 0 .. features: staged[2 + j] = weights[j]
    staged[3 + features] = float64(queries)
    outN = 4 + features
  elif Mode == 3:
    staged[0] = float64(features)
    for col in 0 ..< features: staged[1 + col] = weights[col]
    staged[1 + features] = weights[features]
    staged[2 + features] = float64(queries)
    outN = 3 + features
  else:
    staged[0] = float64(classCount)
    for c in 0 ..< classCount: staged[1 + c] = float64(classes[c])
    let stride = features + 1
    let paramN = (if classCount == 2: stride else: classCount * stride)
    staged[1 + classCount] = float64(paramN)
    for j in 0 ..< paramN: staged[2 + classCount + j] = weights[j]
    staged[2 + classCount + paramN] = float64(queries)
    outN = 3 + classCount + paramN
  for q in 0 ..< queries:
    var pred: float64
    if Mode == 0:
      var score = weights[features]
      for col in 0 ..< features: score += weights[col] * input[queryStart + q * features + col]
      pred = if score >= 0: 1.0 else: 0.0
    elif Mode == 1:
      var score = weights[0] * -1.0
      for col in 0 ..< features: score += weights[col + 1] * input[queryStart + q * features + col]
      pred = if score >= 0: 1.0 else: -1.0
    elif Mode == 3:
      var score = 0.0
      for col in 0 ..< features: score += weights[col] * input[queryStart + q * features + col]
      score += weights[features]
      pred = if score >= 0: 1.0 else: -1.0
    elif classCount == 2:
      var score = weights[0]
      for col in 0 ..< features: score += weights[col + 1] * input[queryStart + q * features + col]
      pred = float64(if score >= 0: classes[1] else: classes[0])
    else:
      var best = 0.0
      var chosen = 0
      let stride = features + 1
      for c in 0 ..< classCount:
        var score = weights[c * stride]
        for col in 0 ..< features: score += weights[c * stride + col + 1] * input[queryStart + q * features + col]
        if c == 0 or score > best: best = score; chosen = c
      pred = float64(classes[chosen])
    staged[outN] = pred
    outN += 1
  if output == nil or capacity < csize_t(outN): return -2
  for i in 0 ..< outN: output[i] = staged[i]
  int64(outN)

proc perceptron*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64 {.cdecl, exportc: "perceptron_rust".} =
  perceptron_impl(input, inputLength, output, capacity)
