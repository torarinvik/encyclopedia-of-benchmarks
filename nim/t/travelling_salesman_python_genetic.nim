import std/math
import std/random

const
  MaxPopulation = 8
  OutputLength = 5

proc routeDistance(x0, y0, x1, y1: float64): float64 =
  let deltaX = x0 - x1
  let deltaY = y0 - y1
  sqrt(deltaX * deltaX + deltaY * deltaY)

proc calculateFitness(chromosomes: array[MaxPopulation, array[3, int]], population: int,
    x0, y0, x1, y1: float64, fitness: var array[MaxPopulation, float64],
    bestPath: var array[3, int], bestDistance: var float64) =
  for chromosomeIndex in 0 ..< population:
    var totalDistance = 0.0
    for edge in 0 ..< 2:
      let firstCity = chromosomes[chromosomeIndex][edge]
      let secondCity = chromosomes[chromosomeIndex][edge + 1]
      if firstCity == 0:
        if secondCity == 1: totalDistance += routeDistance(x0, y0, x1, y1)
        else: totalDistance += routeDistance(x0, y0, x0, y0)
      else:
        if secondCity == 0: totalDistance += routeDistance(x1, y1, x0, y0)
        else: totalDistance += routeDistance(x1, y1, x1, y1)
    fitness[chromosomeIndex] = 1.0 / totalDistance
    if totalDistance < bestDistance:
      bestPath = chromosomes[chromosomeIndex]
      bestDistance = totalDistance

proc repairChild(child: var array[3, int], segmentStart, segmentEnd: int) =
  var uniqueCount = 1
  if child[1] != child[0]: inc uniqueCount
  if child[2] != child[0] and child[2] != child[1]: inc uniqueCount
  if uniqueCount == 3: return
  for segmentIndex in 0 .. segmentEnd - segmentStart:
    var targetIndex = 0
    for chromosomeIndex in 1 ..< 2:
      if chromosomeIndex == segmentStart + segmentIndex: continue
      if child[chromosomeIndex] == child[segmentStart + segmentIndex]:
        targetIndex = chromosomeIndex
        break
    if targetIndex != 0:
      var availableCities = @[1]
      for city in child:
        var cityIndex = 0
        while cityIndex < availableCities.len:
          if availableCities[cityIndex] == city: availableCities.delete(cityIndex)
          else: inc cityIndex
      if availableCities.len > 0:
        child[targetIndex] = availableCities[rand(availableCities.high)]

proc travelling_salesman_python_genetic*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "travelling_salesman_python_genetic".} =
  if input == nil or inputLength != 8: return -1
  for index in 0 ..< 8:
    let valueClass = classify(input[index])
    if valueClass == fcNan or valueClass == fcInf or valueClass == fcNegInf: return -1

  let populationValue = input[0]
  let iterationsValue = input[1]
  let crossoverProbability = input[2]
  let mutationProbability = input[3]
  if populationValue < 2.0 or populationValue > 8.0 or populationValue != floor(populationValue) or int(populationValue) mod 2 != 0: return -1
  if iterationsValue < 0.0 or iterationsValue > 12.0 or iterationsValue != floor(iterationsValue): return -1
  if crossoverProbability < 0.0 or crossoverProbability > 1.0 or
      mutationProbability < 0.0 or mutationProbability > 1.0: return -1
  for index in 4 ..< 8:
    let coordinate = input[index]
    if coordinate < -16.0 or coordinate > 16.0 or coordinate != floor(coordinate): return -1
  if input[4] == input[6] and input[5] == input[7]: return -1

  let population = int(populationValue)
  let iterations = int(iterationsValue)
  let x0 = input[4]
  let y0 = input[5]
  let x1 = input[6]
  let y1 = input[7]
  var chromosomes: array[MaxPopulation, array[3, int]]
  var citiesList: array[1, int] = [1]
  for chromosomeIndex in 0 ..< population:
    # random.sample(cities_list, 1) shuffles this one-city list.
    let sampledIndex = rand(1) mod citiesList.len
    chromosomes[chromosomeIndex] = [0, citiesList[sampledIndex], 0]

  var fitness: array[MaxPopulation, float64]
  var bestPath: array[3, int]
  var bestDistance = Inf
  calculateFitness(chromosomes, population, x0, y0, x1, y1, fitness, bestPath, bestDistance)

  for _ in 0 ..< iterations:
    var totalProbability = 0.0
    for index in 0 ..< population: totalProbability += fitness[index]
    var probabilities: array[MaxPopulation, float64]
    for index in 0 ..< population: probabilities[index] = fitness[index] / totalProbability
    var selected = chromosomes
    for individual in 0 ..< population:
      var cumulative = 0.0
      let roll = rand(1.0)
      for candidate in 0 ..< population:
        cumulative += probabilities[candidate]
        if roll <= cumulative:
          selected[individual] = chromosomes[candidate]
          break
    chromosomes = selected

    for first in 0 ..< population div 2:
      var childA = chromosomes[first]
      var childB = chromosomes[first + population div 2]
      if rand(1.0) <= crossoverProbability:
        let segmentA = rand(2)
        let segmentB = rand(2)
        let segmentStart = min(segmentA, segmentB)
        let segmentEnd = max(segmentA, segmentB)
        for segmentIndex in segmentStart .. segmentEnd:
          swap(childA[segmentIndex], childB[segmentIndex])
        repairChild(childA, segmentStart, segmentEnd)
        repairChild(childB, segmentStart, segmentEnd)
      chromosomes[first] = childA
      chromosomes[first + population div 2] = childB

    for individual in 0 ..< population:
      var chromosome = chromosomes[individual]
      if rand(1.0) <= mutationProbability:
        let locationA = rand(1) + 1
        let locationB = rand(1) + 1
        swap(chromosome[locationA], chromosome[locationB])
      chromosomes[individual] = chromosome
    calculateFitness(chromosomes, population, x0, y0, x1, y1, fitness, bestPath, bestDistance)

  var staged: array[OutputLength, float64]
  staged[0] = 3.0
  staged[1] = float64(bestPath[0])
  staged[2] = float64(bestPath[1])
  staged[3] = float64(bestPath[2])
  staged[4] = bestDistance
  if output == nil or outputCapacity < OutputLength.csize_t: return -2
  for index in 0 ..< OutputLength: output[index] = staged[index]
  int64(OutputLength)
