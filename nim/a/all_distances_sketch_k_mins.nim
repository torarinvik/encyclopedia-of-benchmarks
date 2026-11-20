const MAX_N = 6
const MAX_ASSIGNMENTS = 3
const MAX_INPUT = 27
const MAX_WORDS = 73

proc putI64(output: ptr UncheckedArray[uint8], word: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8: output[8 * word + byte] = uint8((bits shr (8 * byte)) and 255)

proc all_distances_sketch_k_mins*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc:"all_distances_sketch_k_mins".} =
  if input == nil or length < 2 or length > MAX_INPUT: return -1
  let n0 = input[0]
  let assignments0 = input[1]
  if n0 < 1 or n0 > MAX_N or assignments0 < 1 or assignments0 > MAX_ASSIGNMENTS: return -1
  let n = int(n0)
  let assignments = int(assignments0)
  if int(length) != 2 + n + assignments * n: return -1

  var distances: array[MAX_N, int64]
  for item in 0..<n:
    let distance = input[2 + item]
    if distance < 0 or distance > 1_000_000 or (item > 0 and distances[item - 1] >= distance): return -1
    distances[item] = distance
  var ranks: array[MAX_ASSIGNMENTS, array[MAX_N, int64]]
  for assignment in 0..<assignments:
    var seen: array[MAX_N, bool]
    for item in 0..<n:
      let rank = input[2 + n + assignment * n + item]
      if rank < 0 or rank >= n0 or seen[int(rank)]: return -1
      seen[int(rank)] = true
      ranks[assignment][item] = rank

  var staged: array[MAX_WORDS, int64]
  var count = 0
  for assignment in 0..<assignments:
    var bestRank = n0
    for item in 0..<n:
      let rank = ranks[assignment][item]
      if rank < bestRank:
        staged[1 + 4 * count] = int64(assignment)
        staged[2 + 4 * count] = int64(item)
        staged[3 + 4 * count] = rank
        staged[4 + 4 * count] = distances[item]
        inc count
        bestRank = rank
  staged[0] = int64(count)
  let words = 1 + 4 * count
  let bytes = 8 * words
  if output == nil or capacity < csize_t(bytes): return -2
  for word in 0..<words: putI64(output, word, staged[word])
  int64(bytes)
