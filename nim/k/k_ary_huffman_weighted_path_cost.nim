proc k_ary_huffman_weighted_path_cost*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "k_ary_huffman_weighted_path_cost".} =
  if input.isNil or length < 3 or length > 13: return -1
  let arityValue = input[0]
  let countValue = input[1]
  if (arityValue != 3 and arityValue != 4) or countValue < 1 or countValue > 10: return -1
  let arity = int(arityValue)
  let count = int(countValue)
  if length != csize_t(count + 2) or (count > 1 and (count - 1) mod (arity - 1) != 0): return -1

  var weights: array[16, int64]
  var active: array[16, bool]
  for index in 0 ..< count:
    let weight = input[index + 2]
    if weight < 0 or weight > 1000: return -1
    weights[index] = weight
    active[index] = true

  var nodeCount = count
  var activeCount = count
  var cost = 0'i64
  while activeCount > 1:
    var combined = 0'i64
    for pick in 0 ..< arity:
      var best = -1
      for index in 0 ..< nodeCount:
        if not active[index]: continue
        if best == -1:
          best = index
        elif weights[index] < weights[best] or
            (weights[index] == weights[best] and index < best):
          best = index
      if best == -1: return -1
      combined += weights[best]
      active[best] = false
      dec activeCount
    cost += combined
    weights[nodeCount] = combined
    active[nodeCount] = true
    inc nodeCount
    inc activeCount
  cost
