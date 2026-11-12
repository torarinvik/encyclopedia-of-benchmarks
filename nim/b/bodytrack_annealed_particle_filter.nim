import std/[cstddef]

const
  MaxD = 4
  MaxN = 16
  MaxL = 4
  MaxInput = 318
  Q24 = 16_777_216'i64

type
  I64Input = ptr UncheckedArray[int64]
  ByteOutput = ptr UncheckedArray[uint8]
  ParticleBuffers = array[2, array[MaxN, array[MaxD, int64]]]

proc roundAway(numerator, denominator: int64): int64 =
  let magnitude = if numerator < 0: -numerator else: numerator
  var quotient = magnitude div denominator
  let remainder = magnitude mod denominator
  if 2 * remainder >= denominator: inc quotient
  if numerator < 0: -quotient else: quotient

proc putI64Le(output: ByteOutput, offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc bodytrack_annealed_particle_filter*(input: I64Input, length: csize_t,
    output: ByteOutput, outputCapacity: csize_t): int64
    {.cdecl, exportc: "bodytrack_annealed_particle_filter".} =
  if input.isNil or length < 3 or length > csize_t(MaxInput): return -1
  let dValue = input[0]
  let nValue = input[1]
  let layersValue = input[2]
  if dValue < 1 or dValue > MaxD or nValue < 2 or nValue > MaxN or
      layersValue < 1 or layersValue > MaxL: return -1
  let d, n, layers = int(dValue), int(nValue), int(layersValue)
  let expected = 2 + d + 2 * layers + n * d + (layers - 1) * n * (d + 1)
  if length != csize_t(expected): return -1

  let targetAt = 3
  let betaAt = targetAt + d
  let sigmaAt = betaAt + layers
  let poseAt = sigmaAt + layers - 1
  let uniformAt = poseAt + n * d
  let shockAt = uniformAt + (layers - 1) * n
  var target: array[MaxD, int64]
  var beta: array[MaxL, int64]
  var sigma: array[MaxL - 1, int64]
  for axis in 0 ..< d:
    target[axis] = input[targetAt + axis]
    if target[axis] < -10000 or target[axis] > 10000: return -1
  for layer in 0 ..< layers:
    beta[layer] = input[betaAt + layer]
    if beta[layer] < 1 or beta[layer] > 8 or
        (layer > 0 and beta[layer] <= beta[layer - 1]): return -1
  for layer in 0 ..< layers - 1:
    sigma[layer] = input[sigmaAt + layer]
    if sigma[layer] < 0 or sigma[layer] > 2000 or
        (layer > 0 and sigma[layer] > sigma[layer - 1]): return -1
  for item in 0 ..< n * d:
    if input[poseAt + item] < -10000 or input[poseAt + item] > 10000: return -1
  for item in 0 ..< (layers - 1) * n:
    if input[uniformAt + item] < 0 or input[uniformAt + item] >= Q24: return -1
  for item in 0 ..< (layers - 1) * n * d:
    if input[shockAt + item] < -3000 or input[shockAt + item] > 3000: return -1

  let required = 8 * d
  if outputCapacity < csize_t(required) or output.isNil: return -2
  var population: ParticleBuffers
  var weights: array[MaxN, int64]
  var estimate: array[MaxD, int64]
  for particle in 0 ..< n:
    for axis in 0 ..< d:
      population[0][particle][axis] = input[poseAt + particle * d + axis]
  var active = 0
  for layer in 0 ..< layers:
    var totalWeight = 0'i64
    for particle in 0 ..< n:
      var squaredDistance = 0'i64
      for axis in 0 ..< d:
        let delta = population[active][particle][axis] - target[axis]
        squaredDistance += delta * delta
      let energy = squaredDistance div 10000
      let base = Q24 * 100000 div (100000 + energy)
      var weight = base
      for power in 1 ..< int(beta[layer]): weight = weight * base div Q24
      weights[particle] = weight
      totalWeight += weight
    if layer + 1 == layers:
      for axis in 0 ..< d:
        var moment = 0'i64
        for particle in 0 ..< n:
          moment += weights[particle] * population[active][particle][axis]
        estimate[axis] = roundAway(moment, totalWeight)
      break
    let destination = 1 - active
    for child in 0 ..< n:
      let threshold = input[uniformAt + layer * n + child] * totalWeight div Q24
      var cumulative = 0'i64
      var ancestor = 0
      while cumulative <= threshold:
        cumulative += weights[ancestor]
        inc ancestor
      dec ancestor
      for axis in 0 ..< d:
        let shock = input[shockAt + layer * n * d + child * d + axis]
        let movement = roundAway(sigma[layer] * shock, 1000)
        let coordinate = population[active][ancestor][axis] + movement
        population[destination][child][axis] = max(-10000'i64, min(10000'i64, coordinate))
    active = destination
  for axis in 0 ..< d: putI64Le(output, 8 * axis, estimate[axis])
  int64(required)
