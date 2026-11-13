## Bounded knapsack by residue-class sliding maxima.
proc bounded_knapsack_monotone_queue*(packed: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "bounded_knapsack_monotone_queue".} =
  if packed == nil or length < 2 or length > 51:
    return -1
  if packed[0] < 0 or packed[0] > 64 or packed[1] < 0 or packed[1] > 16:
    return -1
  let capacity = int(packed[0])
  let types = int(packed[1])
  if length != csize_t(2 + 3 * types):
    return -1
  for item in 0 ..< types:
    let weight = packed[2 + 3 * item]
    let value = packed[3 + 3 * item]
    let count = packed[4 + 3 * item]
    if weight < 1 or weight > 16 or value < 0 or value > 100 or count < 0 or count > 16:
      return -1

  var dp: array[65, int64]
  var next: array[65, int64]
  var queueScore: array[65, int64]
  var queueIndex: array[65, int]
  for item in 0 ..< types:
    let weight = int(packed[2 + 3 * item])
    let value = packed[3 + 3 * item]
    let count = int(packed[4 + 3 * item])
    for residue in 0 ..< min(weight, capacity + 1):
      var head = 0
      var tail = 0
      let maxT = (capacity - residue) div weight
      for t in 0 .. maxT:
        let current = residue + t * weight
        let score = dp[current] - int64(t) * value
        while tail > head and queueScore[tail - 1] <= score:
          dec tail
        queueIndex[tail] = t
        queueScore[tail] = score
        inc tail
        let firstAllowed = max(0, t - count)
        while head < tail and queueIndex[head] < firstAllowed:
          inc head
        next[current] = int64(t) * value + queueScore[head]
    for c in 0 .. capacity:
      dp[c] = next[c]
  dp[capacity]
