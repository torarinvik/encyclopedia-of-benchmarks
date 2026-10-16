import math

const InvalidResult = -1.0e300

proc coefficients(kind: int64, frequency, samplerate, gainDb, qFactor: float64): array[6, float64] =
  let w0 = 6.283185307179586476925286766559 * frequency / samplerate
  let sine = sin(w0)
  let cosine = cos(w0)
  let alpha = sine / (2.0 * qFactor)
  var a0 = 1.0 + alpha
  var a1 = -2.0 * cosine
  var a2 = 1.0 - alpha
  var b0, b1, b2: float64
  if kind == 0:
    b0 = (1.0 - cosine) / 2.0; b1 = 1.0 - cosine; b2 = b0
  elif kind == 1:
    b0 = (1.0 + cosine) / 2.0; b1 = -1.0 - cosine; b2 = b0
  elif kind == 2:
    b0 = sine / 2.0; b1 = 0.0; b2 = -b0
  elif kind == 3:
    b0 = 1.0 - alpha; b1 = -2.0 * cosine; b2 = 1.0 + alpha
    a0 = b2; a1 = b1; a2 = b0
  elif kind == 4:
    let bigA = pow(10.0, gainDb / 40.0)
    b0 = 1.0 + alpha * bigA; b1 = -2.0 * cosine; b2 = 1.0 - alpha * bigA
    a0 = 1.0 + alpha / bigA; a1 = -2.0 * cosine; a2 = 1.0 - alpha / bigA
  elif kind == 5 or kind == 6:
    let bigA = pow(10.0, gainDb / 40.0)
    let pmc = (bigA + 1.0) - (bigA - 1.0) * cosine
    let ppmc = (bigA + 1.0) + (bigA - 1.0) * cosine
    let mpc = (bigA - 1.0) - (bigA + 1.0) * cosine
    let pmpc = (bigA - 1.0) + (bigA + 1.0) * cosine
    let aa2 = 2.0 * sqrt(bigA) * alpha
    if kind == 5:
      b0 = bigA * (pmc + aa2); b1 = 2.0 * bigA * mpc; b2 = bigA * (pmc - aa2)
      a0 = ppmc + aa2; a1 = -2.0 * pmpc; a2 = ppmc - aa2
    else:
      b0 = bigA * (ppmc + aa2); b1 = -2.0 * bigA * pmpc; b2 = bigA * (ppmc - aa2)
      a0 = pmc + aa2; a1 = 2.0 * mpc; a2 = pmc - aa2
  elif kind == 7:
    b0 = 1.0; b1 = -2.0 * cosine; b2 = 1.0
  else:
    b0 = alpha; b1 = 0.0; b2 = -alpha
  [a0, a1, a2, b0, b1, b2]

proc butterworth_filter*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "butterworth_filter".} =
  if values == nil or length != 6: return InvalidResult
  let kind = values[0]
  let coefficientIndex = values[1]
  let frequency = values[2]
  let samplerate = values[3]
  let gainMilliDb = values[4]
  let qMicro = values[5]
  if kind < 0 or kind > 8 or coefficientIndex < 0 or coefficientIndex > 5 or
      frequency < 1 or frequency > 95999 or samplerate < 1 or samplerate > 192000 or
      2 * frequency >= samplerate: return InvalidResult
  if qMicro != -1 and (qMicro < 1 or qMicro > 10000000): return InvalidResult
  let needsGain = kind >= 4 and kind <= 6
  if needsGain:
    if gainMilliDb < -60000 or gainMilliDb > 60000: return InvalidResult
  elif gainMilliDb != 0: return InvalidResult
  let gainDb = if needsGain: float64(gainMilliDb) / 1000.0 else: 0.0
  let qFactor = if qMicro == -1: 1.0 / sqrt(2.0) else: float64(qMicro) / 1000000.0
  let output = coefficients(kind, float64(frequency), float64(samplerate), gainDb, qFactor)
  output[int(coefficientIndex)]
