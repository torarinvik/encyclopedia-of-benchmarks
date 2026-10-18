import std/[math]

const MaxOutput = 38
const JacobiTolerance = 1e-14
const MinEigenGap = 1e-8

proc finite(x: float64): bool = classify(x) notin {fcNan, fcInf, fcNegInf}

proc diagonalize(a: var seq[float64], vectors: var seq[float64], n: int,
                values: var array[4, float64]): bool =
  for i in 0 ..< n:
    for j in 0 ..< n:
      vectors[i * 4 + j] = (if i == j: 1.0 else: 0.0)
  var converged = false
  for sweep in 0 .. 64:
    var largest = 0.0
    for p in 0 ..< n:
      for q in p + 1 ..< n: largest = max(largest, abs(a[p * 4 + q]))
    if largest <= JacobiTolerance:
      converged = true
      break
    if sweep == 64: break
    for p in 0 ..< n:
      for q in p + 1 ..< n:
        let apq = a[p * 4 + q]
        if abs(apq) <= JacobiTolerance: continue
        let tau = (a[q * 4 + q] - a[p * 4 + p]) / (2.0 * apq)
        let sign = (if tau >= 0.0: 1.0 else: -1.0)
        let t = sign / (abs(tau) + sqrt(1.0 + tau * tau))
        let c = 1.0 / sqrt(1.0 + t * t)
        let s = t * c
        let app = a[p * 4 + p]
        let aqq = a[q * 4 + q]
        a[p * 4 + p] = app - t * apq
        a[q * 4 + q] = aqq + t * apq
        a[p * 4 + q] = 0.0
        a[q * 4 + p] = 0.0
        for r in 0 ..< n:
          if r != p and r != q:
            let arp = a[r * 4 + p]
            let arq = a[r * 4 + q]
            a[r * 4 + p] = c * arp - s * arq
            a[p * 4 + r] = a[r * 4 + p]
            a[r * 4 + q] = s * arp + c * arq
            a[q * 4 + r] = a[r * 4 + q]
          let vrp = vectors[r * 4 + p]
          let vrq = vectors[r * 4 + q]
          vectors[r * 4 + p] = c * vrp - s * vrq
          vectors[r * 4 + q] = s * vrp + c * vrq
  if not converged: return false
  for i in 0 ..< n: values[i] = a[i * 4 + i]
  for i in 0 ..< n:
    for j in i + 1 ..< n:
      if values[j] > values[i]:
        swap(values[i], values[j])
        for r in 0 ..< n: swap(vectors[r * 4 + i], vectors[r * 4 + j])
  true

proc principle_component_analysis*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64 {.cdecl, exportc: "principle_component_analysis".} =
  if input == nil or inputLength < 3 or inputLength > 35: return -1
  for i in 0 ..< int(inputLength):
    if not finite(input[i]): return -1
  for i in 0 ..< 3:
    if input[i] != floor(input[i]): return -1
  if input[0] < 3 or input[0] > 8 or input[1] < 2 or input[1] > 4 or input[2] < 1 or input[2] > 4: return -1
  let samples = int(input[0])
  let features = int(input[1])
  let components = int(input[2])
  if samples <= features or components > features or inputLength != csize_t(3 + samples * features): return -1
  var rows = newSeq[float64](32)
  var means = newSeq[float64](4)
  for r in 0 ..< samples:
    for c in 0 ..< features:
      let x = input[3 + r * features + c]
      if x != floor(x) or x < -9 or x > 9: return -1
      rows[r * 4 + c] = x
      means[c] += x
      if not finite(means[c]): return -1
  for c in 0 ..< features: means[c] /= float64(samples)
  var variances = newSeq[float64](4)
  for r in 0 ..< samples:
    for c in 0 ..< features:
      let d = rows[r * 4 + c] - means[c]
      variances[c] += d * d
  var scales = newSeq[float64](4)
  for c in 0 ..< features:
    variances[c] /= float64(samples)
    if variances[c] <= 0 or not finite(variances[c]): return -1
    scales[c] = sqrt(variances[c])
  var z = newSeq[float64](32)
  var pcaMeans = newSeq[float64](4)
  for r in 0 ..< samples:
    for c in 0 ..< features:
      z[r * 4 + c] = (rows[r * 4 + c] - means[c]) / scales[c]
      pcaMeans[c] += z[r * 4 + c]
  for c in 0 ..< features: pcaMeans[c] /= float64(samples)
  var centered = newSeq[float64](32)
  for r in 0 ..< samples:
    for c in 0 ..< features: centered[r * 4 + c] = z[r * 4 + c] - pcaMeans[c]
  var covariance = newSeq[float64](16)
  for i in 0 ..< features:
    for j in i ..< features:
      var total = 0.0
      for r in 0 ..< samples: total += centered[r * 4 + i] * centered[r * 4 + j]
      covariance[i * 4 + j] = total / float64(samples - 1)
      covariance[j * 4 + i] = covariance[i * 4 + j]
  var vectors = newSeq[float64](16)
  var eigenvalues: array[4, float64]
  if not diagonalize(covariance, vectors, features, eigenvalues): return -1
  for i in 0 ..< features:
    if eigenvalues[i] <= 0 or not finite(eigenvalues[i]) or
        (i + 1 < features and eigenvalues[i] - eigenvalues[i + 1] <= MinEigenGap): return -1
  var totalVariance = 0.0
  for i in 0 ..< features: totalVariance += eigenvalues[i]
  if totalVariance <= 0 or not finite(totalVariance): return -1
  var scores = newSeq[float64](32)
  for k in 0 ..< components:
    for r in 0 ..< samples:
      for c in 0 ..< features: scores[k * 8 + r] += centered[r * 4 + c] * vectors[c * 4 + k]
    var pivot = 0
    for r in 1 ..< samples:
      if abs(scores[k * 8 + r]) > abs(scores[k * 8 + pivot]): pivot = r
    if scores[k * 8 + pivot] < 0:
      for r in 0 ..< samples: scores[k * 8 + r] = -scores[k * 8 + r]
  var staged: array[MaxOutput, float64]
  staged[0] = float64(samples)
  staged[1] = float64(components)
  var pos = 2
  for r in 0 ..< samples:
    for k in 0 ..< components:
      staged[pos] = scores[k * 8 + r]
      inc pos
  for k in 0 ..< components:
    staged[pos] = eigenvalues[k] / totalVariance
    inc pos
  for i in 0 ..< pos:
    if not finite(staged[i]): return -1
  if output == nil or capacity < csize_t(pos): return -2
  for i in 0 ..< pos: output[i] = staged[i]
  int64(pos)
