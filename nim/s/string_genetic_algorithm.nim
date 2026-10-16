const
  PopulationSize = 200
  SelectedSize = 50
  EliteSize = 66
  RngModulus = 2_147_483_647'u64

proc nextRandom(state: var uint64): uint64 =
  state = (state * 48_271'u64) mod RngModulus
  state

proc writeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xff'u64)

proc string_genetic_algorithm*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "string_genetic_algorithm".} =
  if values == nil or length < 6 or length > 44: return -2
  let targetLengthValue = values[0]
  let geneCountValue = values[1]
  let seedValue = values[2]
  let maxGenerationsValue = values[3]
  if targetLengthValue < 1 or targetLengthValue > 8 or geneCountValue < 1 or geneCountValue > 32 or
      seedValue < 1 or seedValue >= 2_147_483_647 or maxGenerationsValue < 1 or maxGenerationsValue > 1000: return -2
  let targetLength = int(targetLengthValue)
  let geneCount = int(geneCountValue)
  let maxGenerations = int(maxGenerationsValue)
  if int(length) != 4 + targetLength + geneCount: return -2
  var target: array[8, uint8]
  var genes: array[32, uint8]
  for i in 0 ..< targetLength:
    let value = values[4 + i]
    if value < 32 or value > 126: return -2
    target[i] = uint8(value)
  for i in 0 ..< geneCount:
    let value = values[4 + targetLength + i]
    if value < 32 or value > 126: return -2
    genes[i] = uint8(value)
  for position in 0 ..< targetLength:
    var found = false
    for gene in 0 ..< geneCount:
      if genes[gene] == target[position]: found = true
    if not found: return -2
  if output == nil: return -2

  var state = uint64(seedValue)
  var population: array[PopulationSize, uint64]
  var nextPopulation: array[PopulationSize, uint64]
  var scores: array[PopulationSize, uint8]
  var order: array[PopulationSize, int]
  for individual in 0 ..< PopulationSize:
    var word = 0'u64
    for position in 0 ..< targetLength:
      let gene = genes[int(nextRandom(state) mod uint64(geneCount))]
      word = word or (uint64(gene) shl (8 * position))
    population[individual] = word

  var totalPopulation = 0'i64
  for generation in 1 .. maxGenerations:
    totalPopulation += int64(PopulationSize)
    for individual in 0 ..< PopulationSize:
      var score = 0'u8
      for position in 0 ..< targetLength:
        if uint8((population[individual] shr (8 * position)) and 0xff'u64) == target[position]: inc score
      scores[individual] = score
      order[individual] = individual
      if int(score) == targetLength:
        if outputCapacity < 16: return -2
        writeI64Le(output, 0, int64(generation))
        writeI64Le(output, 8, totalPopulation)
        return 16
    for index in 1 ..< PopulationSize:
      let selected = order[index]
      var insertion = index
      while insertion > 0 and scores[order[insertion - 1]] < scores[selected]:
        order[insertion] = order[insertion - 1]
        dec insertion
      order[insertion] = selected
    var nextCount = 0
    while nextCount < EliteSize:
      nextPopulation[nextCount] = population[order[nextCount]]
      inc nextCount
    for parentRank in 0 ..< SelectedSize:
      if nextCount >= PopulationSize: break
      let first = population[order[parentRank]]
      let childCount = min(10, int(scores[order[parentRank]]) * 100 div targetLength + 1)
      for _ in 0 ..< childCount:
        if nextCount >= PopulationSize: break
        let second = population[order[int(nextRandom(state) mod 51'u64)]]
        let cut = int(nextRandom(state) mod uint64(targetLength))
        var children: array[2, uint64]
        for position in 0 ..< targetLength:
          let shift = 8 * position
          let firstGene = (first shr shift) and 0xff'u64
          let secondGene = (second shr shift) and 0xff'u64
          if position < cut:
            children[0] = children[0] or (firstGene shl shift)
            children[1] = children[1] or (secondGene shl shift)
          else:
            children[0] = children[0] or (secondGene shl shift)
            children[1] = children[1] or (firstGene shl shift)
        for child in 0 ..< 2:
          if nextRandom(state) mod 5'u64 < 2'u64:
            let position = int(nextRandom(state) mod uint64(targetLength))
            let shift = 8 * position
            let replacement = uint64(genes[int(nextRandom(state) mod uint64(geneCount))])
            children[child] = (children[child] and not (0xff'u64 shl shift)) or (replacement shl shift)
          if nextCount < PopulationSize:
            nextPopulation[nextCount] = children[child]
            inc nextCount
        if nextCount == PopulationSize: break
      if nextCount == PopulationSize: break
    population = nextPopulation
  -1
