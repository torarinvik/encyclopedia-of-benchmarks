const
  ParticleCount = 50
  DimensionCount = 5
  IterationCount = 1000
  MaxInputLength = 2
  OutputValueCount = 1 + DimensionCount + IterationCount
  OutputBytes = OutputValueCount * 8

proc nextUniform(state: var uint64): float64 =
  state = state xor (state shl 13)
  state = state xor (state shr 7)
  state = state xor (state shl 17)
  float64(state shr 11) * (1.0 / 9007199254740992.0)

proc sphere(point: array[DimensionCount, float64]): float64 =
  var cost = 0.0
  for coordinate in 0 ..< DimensionCount:
    cost += point[coordinate] * point[coordinate]
  cost

proc writeF64Le(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc particle_swarm_optimization*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "particle_swarm_optimization".} =
  if input == nil or length < 1 or length > csize_t(MaxInputLength) or length != 1 or input[0] <= 0:
    return -1
  if output == nil or outputCapacity < csize_t(OutputBytes):
    return -2

  var randomState = uint64(input[0])
  var positions: array[ParticleCount, array[DimensionCount, float64]]
  var velocities: array[ParticleCount, array[DimensionCount, float64]]
  var personalPositions: array[ParticleCount, array[DimensionCount, float64]]
  var personalCosts: array[ParticleCount, float64]
  var globalPosition: array[DimensionCount, float64]
  var history: array[IterationCount, float64]
  var globalCost = 1.7976931348623157e308

  for particle in 0 ..< ParticleCount:
    for coordinate in 0 ..< DimensionCount:
      positions[particle][coordinate] = -10.0 + 20.0 * nextUniform(randomState)
      personalPositions[particle][coordinate] = positions[particle][coordinate]
    personalCosts[particle] = sphere(positions[particle])
    if personalCosts[particle] < globalCost:
      globalCost = personalCosts[particle]
      globalPosition = personalPositions[particle]

  var inertia = 1.0
  for iteration in 0 ..< IterationCount:
    for particle in 0 ..< ParticleCount:
      var personalRandom: array[DimensionCount, float64]
      var socialRandom: array[DimensionCount, float64]
      for coordinate in 0 ..< DimensionCount:
        personalRandom[coordinate] = nextUniform(randomState)
      for coordinate in 0 ..< DimensionCount:
        socialRandom[coordinate] = nextUniform(randomState)

      for coordinate in 0 ..< DimensionCount:
        let cognitive = (2.0 * personalRandom[coordinate]) *
          (personalPositions[particle][coordinate] - positions[particle][coordinate])
        let social = (2.0 * socialRandom[coordinate]) *
          (globalPosition[coordinate] - positions[particle][coordinate])
        velocities[particle][coordinate] = inertia * velocities[particle][coordinate] + cognitive + social
        positions[particle][coordinate] += velocities[particle][coordinate]

      let cost = sphere(positions[particle])
      if cost < personalCosts[particle]:
        personalCosts[particle] = cost
        personalPositions[particle] = positions[particle]
        if personalCosts[particle] < globalCost:
          globalCost = personalCosts[particle]
          globalPosition = personalPositions[particle]
    history[iteration] = globalCost
    inertia *= 0.99

  var offset = 0
  writeF64Le(output, offset, globalCost)
  offset += 8
  for coordinate in 0 ..< DimensionCount:
    writeF64Le(output, offset, globalPosition[coordinate])
    offset += 8
  for iteration in 0 ..< IterationCount:
    writeF64Le(output, offset, history[iteration])
    offset += 8
  int64(OutputBytes)
