## Seeded binary genetic minimization with the pinned MATLAB operator order.
import math

const MaxPopulation = 16

proc nextWord(state: var uint64): uint64 =
  state = state +% 0x9E3779B97F4A7C15'u64
  var value = state
  value = (value xor (value shr 30)) *% 0xBF58476D1CE4E5B9'u64
  value = (value xor (value shr 27)) *% 0x94D049BB133111EB'u64
  value xor (value shr 31)

proc bounded(state: var uint64, bound: uint64): uint64 =
  let threshold = (0'u64 -% bound) mod bound
  while true:
    let value = nextWord(state)
    if value >= threshold: return value mod bound
  0

proc unitRandom(state: var uint64): float64 =
  float64(nextWord(state) shr 11) / 9007199254740992.0

proc costOf(candidate: uint64, nVar: int): int64 =
  var cost = 0'i64
  for gene in 0 ..< nVar:
    cost += int64((candidate shr gene) and 1'u64)
  cost

proc selectParent(probabilities: array[MaxPopulation, float64], nPop: int,
                  total: float64, state: var uint64): int =
  let target = unitRandom(state) * total
  var cumulative = 0.0
  for index in 0 ..< nPop:
    cumulative += probabilities[index]
    if target <= cumulative: return index
  nPop - 1

proc crossover(first, second: uint64, nVar: int, state: var uint64): tuple[firstChild, secondChild: uint64] =
  let kind = bounded(state, 3)
  var child1 = 0'u64
  var child2 = 0'u64
  if kind == 0:
    let cut = int(bounded(state, uint64(nVar - 1))) + 1
    for gene in 0 ..< nVar:
      let bit = 1'u64 shl gene
      if gene < cut:
        child1 = child1 or (first and bit)
        child2 = child2 or (second and bit)
      else:
        child1 = child1 or (second and bit)
        child2 = child2 or (first and bit)
  elif kind == 1:
    var low = int(bounded(state, uint64(nVar))) + 1
    var high = int(bounded(state, uint64(nVar - 1))) + 1
    if high >= low: inc high
    if high < low: swap(low, high)
    for gene in 0 ..< nVar:
      let bit = 1'u64 shl gene
      let exchange = gene >= low and gene < high
      if exchange:
        child1 = child1 or (second and bit)
        child2 = child2 or (first and bit)
      else:
        child1 = child1 or (first and bit)
        child2 = child2 or (second and bit)
  else:
    for gene in 0 ..< nVar:
      let bit = 1'u64 shl gene
      if bounded(state, 2) == 1:
        child1 = child1 or (first and bit)
        child2 = child2 or (second and bit)
      else:
        child1 = child1 or (second and bit)
        child2 = child2 or (first and bit)
  (child1, child2)

proc binary_genetic_algorithm*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "binary_genetic_algorithm".} =
  if input == nil or length < 4 or length > 5: return -1
  let seedValue = input[0]
  let nVarValue = input[1]
  let nPopValue = input[2]
  let maxItValue = input[3]
  if length != 4 or seedValue < 0 or nVarValue < 2 or nVarValue > 32 or
      nPopValue < 2 or nPopValue > 16 or nPopValue mod 2 != 0 or
      maxItValue < 1 or maxItValue > 32: return -1
  let nVar = int(nVarValue)
  let nPop = int(nPopValue)
  let maxIt = int(maxItValue)
  var state = uint64(seedValue)
  var population: array[MaxPopulation, uint64]
  var bestCost = int64(nVar + 1)

  for member in 0 ..< nPop:
    var candidate = 0'u64
    for gene in 0 ..< nVar:
      candidate = candidate or (bounded(state, 2) shl gene)
    population[member] = candidate
    let cost = costOf(candidate, nVar)
    if cost < bestCost: bestCost = cost

  for _ in 0 ..< maxIt:
    var costs: array[MaxPopulation, int64]
    var totalCost = 0'i64
    for member in 0 ..< nPop:
      costs[member] = costOf(population[member], nVar)
      totalCost += costs[member]
    let average = float64(totalCost) / float64(nPop)
    var probabilities: array[MaxPopulation, float64]
    var probabilityTotal = 0.0
    for member in 0 ..< nPop:
      let scaled = if average != 0.0: float64(costs[member]) / average else: float64(costs[member])
      probabilities[member] = exp(-scaled)
      probabilityTotal += probabilities[member]

    let pairs = nPop div 2
    var firstChildren: array[MaxPopulation div 2, uint64]
    var secondChildren: array[MaxPopulation div 2, uint64]
    for pair in 0 ..< pairs:
      let firstIndex = selectParent(probabilities, nPop, probabilityTotal, state)
      let secondIndex = selectParent(probabilities, nPop, probabilityTotal, state)
      (firstChildren[pair], secondChildren[pair]) =
        crossover(population[firstIndex], population[secondIndex], nVar, state)

    var offspring: array[MaxPopulation, uint64]
    for pair in 0 ..< pairs:
      offspring[pair] = firstChildren[pair]
      offspring[pairs + pair] = secondChildren[pair]
    for member in 0 ..< nPop:
      for gene in 0 ..< nVar:
        if unitRandom(state) < 0.02: offspring[member] = offspring[member] xor (1'u64 shl gene)
      let cost = costOf(offspring[member], nVar)
      if cost < bestCost: bestCost = cost

    var merged: array[MaxPopulation * 2, uint64]
    var mergedCount = 0
    for member in 0 ..< nPop:
      merged[mergedCount] = population[member]
      inc mergedCount
    for member in 0 ..< nPop:
      merged[mergedCount] = offspring[member]
      inc mergedCount
    for index in 1 ..< mergedCount:
      let selected = merged[index]
      let selectedCost = costOf(selected, nVar)
      var insertion = index
      while insertion > 0 and costOf(merged[insertion - 1], nVar) > selectedCost:
        merged[insertion] = merged[insertion - 1]
        dec insertion
      merged[insertion] = selected
    for member in 0 ..< nPop: population[member] = merged[member]
  bestCost
