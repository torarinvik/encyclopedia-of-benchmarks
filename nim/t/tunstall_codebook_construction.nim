const MaxS = 4222124650659840'i64
const ResultFactor = MaxS + 1

proc tunstall_codebook_construction*(input: ptr UncheckedArray[int64], len: csize_t): int64 {.cdecl, exportc: "tunstall_codebook_construction".} =
  if input.isNil or len < 4 or len > 7: return -1
  if input[0] < 2 or input[0] > 4 or input[1] < 2 or input[1] > 4: return -1
  let k = int(input[0])
  let bits = int(input[1])
  if len != csize_t(k + 2): return -1
  var weights: array[4, int64]
  var total = 0'i64
  for i in 0..<k:
    let weight = input[2 + i]
    if weight <= 0 or weight > 8: return -1
    weights[i] = weight
    total += weight
  if total > 8: return -1

  var powers: array[17, int64]
  powers[0] = 1
  for i in 1..16: powers[i] = powers[i - 1] * total
  var cap = 1
  for bit in 0..<bits: cap *= 2
  var target = cap
  while (target - 1) mod (k - 1) != 0: dec target

  var products: array[31, int64]
  var depths: array[31, int]
  var phraseKeys: array[31, uint64]
  var leaves: array[16, int]
  var nodeCount = 1
  var leafCount = 0
  for symbol in 0..<k:
    let node = nodeCount
    inc nodeCount
    products[node] = weights[symbol]
    depths[node] = 1
    phraseKeys[node] = uint64(symbol + 1) shl 56
    leaves[leafCount] = node
    inc leafCount

  var scaledExpectation = powers[16]
  while leafCount < target:
    var bestPosition = 0
    var bestNode = leaves[0]
    var bestProbability = products[bestNode] * powers[15 - depths[bestNode]]
    for position in 1..<leafCount:
      let candidate = leaves[position]
      let probability = products[candidate] * powers[15 - depths[candidate]]
      if probability > bestProbability or (probability == bestProbability and phraseKeys[candidate] < phraseKeys[bestNode]):
        bestPosition = position
        bestNode = candidate
        bestProbability = probability

    scaledExpectation += products[bestNode] * powers[16 - depths[bestNode]]
    dec leafCount
    leaves[bestPosition] = leaves[leafCount]
    for symbol in 0..<k:
      let child = nodeCount
      inc nodeCount
      products[child] = products[bestNode] * weights[symbol]
      depths[child] = depths[bestNode] + 1
      let shift = 4 * (14 - depths[bestNode])
      phraseKeys[child] = phraseKeys[bestNode] or (uint64(symbol + 1) shl shift)
      leaves[leafCount] = child
      inc leafCount
  if scaledExpectation > MaxS: return -1
  int64(target) * ResultFactor + scaledExpectation
