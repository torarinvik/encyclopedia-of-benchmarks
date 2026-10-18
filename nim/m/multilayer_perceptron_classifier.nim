import math

const MaxOutput = 26

proc finite(x: float64): bool = classify(x) notin {fcNan, fcInf, fcNegInf}

proc multilayer_perceptron_classifier*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "multilayer_perceptron_classifier".} =
  if input == nil or inputLength > 16 or inputLength != 15: return -1
  for i in 0 ..< 15:
    if not finite(input[i]): return -1
  if input[0] != floor(input[0]) or input[0] < 1 or input[0] > 12: return -1
  if input[1] notin {0.05, 0.1, 0.2} or input[2] notin {0.5, 0.75, 1.0}: return -1
  let epochs = int(input[0])
  for i in 0 ..< 8:
    let value = input[3 + i]
    if value < -2 or value > 2 or value * 4 != floor(value * 4): return -1
  var labels: array[4, int]
  for i in 0 ..< 4:
    let label = input[11 + i]
    if label != floor(label) or label < 0 or label > 2: return -1
    labels[i] = int(label)
  var w1 = [0.30471707975443135, -1.0399841062404955,
    0.7504511958064572, 0.9405647163912139,
    -1.9510351886538364, -1.302179506862318]
  var w2 = [0.12784040316728537, -0.3162425923435822, -0.016801157504288795,
    -0.85304392757358, 0.8793979748628286, 0.7777919354289483]
  var accuracies: array[12, float64]
  var losses: array[12, float64]
  var rate = input[1]
  for epoch in 0 ..< epochs:
    for rowIndex in 0 ..< 3:
      var row: array[3, float64]
      row[0] = input[3 + rowIndex * 2]
      row[1] = input[4 + rowIndex * 2]
      row[2] = 1.0
      var z1: array[2, float64]
      for j in 0 ..< 2:
        var total = 0.0
        for i in 0 ..< 3: total += row[i] * w1[i * 2 + j]
        z1[j] = total
      var hidden: array[2, float64]
      for j in 0 ..< 2: hidden[j] = max(0.0, z1[j])
      var z2: array[3, float64]
      for k in 0 ..< 3:
        var total = 0.0
        for j in 0 ..< 2: total += hidden[j] * w2[j * 3 + k]
        z2[k] = total
      var deltaOut: array[3, float64]
      for k in 0 ..< 3:
        deltaOut[k] = z2[k]
        if labels[rowIndex] == k: deltaOut[k] -= 0.99
      var deltaHidden: array[2, float64]
      for j in 0 ..< 2:
        var total = 0.0
        for k in 0 ..< 3: total += deltaOut[k] * w2[j * 3 + k]
        if z1[j] > 0.0: deltaHidden[j] = total else: deltaHidden[j] = 0.0
      var gradW2: array[6, float64]
      for j in 0 ..< 2:
        for k in 0 ..< 3: gradW2[j * 3 + k] = hidden[j] * deltaOut[k]
      var gradW1: array[6, float64]
      for i in 0 ..< 3:
        for j in 0 ..< 2: gradW1[i * 2 + j] = row[i] * deltaHidden[j]
      for i in 0 ..< 3:
        for j in 0 ..< 2: w1[i * 2 + j] -= rate * gradW1[i * 2 + j]
      for j in 0 ..< 2:
        for k in 0 ..< 3: w2[j * 3 + k] -= rate * gradW2[j * 3 + k]
    var row: array[3, float64]
    row[0] = input[9]; row[1] = input[10]; row[2] = 1.0
    var z1: array[2, float64]
    for j in 0 ..< 2:
      var total = 0.0
      for i in 0 ..< 3: total += row[i] * w1[i * 2 + j]
      z1[j] = total
    var hidden: array[2, float64]
    for j in 0 ..< 2: hidden[j] = max(0.0, z1[j])
    var predicted: array[3, float64]
    for k in 0 ..< 3:
      var total = 0.0
      for j in 0 ..< 2: total += hidden[j] * w2[j * 3 + k]
      predicted[k] = total
    var best = 0
    for k in 1 ..< 3:
      if predicted[k] > predicted[best]: best = k
    accuracies[epoch] = if best == labels[3]: 1.0 else: 0.0
    var loss = 0.0
    for k in 0 ..< 3:
      var difference = predicted[k]
      if labels[3] == k: difference -= 0.99
      loss += difference * difference
    losses[epoch] = loss / 2.0
    rate *= input[2]
  var staged: array[MaxOutput, float64]
  staged[0] = float64(epochs)
  var mean = 0.0
  for epoch in 0 ..< epochs:
    staged[1 + epoch] = accuracies[epoch]
    staged[1 + epochs + epoch] = losses[epoch]
    mean += accuracies[epoch]
  mean /= float64(epochs)
  staged[1 + 2 * epochs] = mean
  let outputSize = 2 + 2 * epochs
  if output == nil or capacity < csize_t(outputSize): return -2
  for i in 0 ..< outputSize: output[i] = staged[i]
  int64(outputSize)
