import std/posix

const MaxN = 32
const MaxM = 128
const MaxInput = 258

proc sugiyama_longest_path_layer_assignment*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "sugiyama_longest_path_layer_assignment".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxInput + 1): return -1
  let n64 = input[0]
  let m64 = input[1]
  if n64 < 0 or n64 > MaxN.int64 or m64 < 0 or m64 > MaxM.int64: return -1
  let n = int(n64)
  let m = int(m64)
  if int64(length) != 2 + 2 * m64: return -1

  var adjacency: array[MaxN, uint32]
  for edge in 0..<m:
    let source = input[2 + 2 * edge]
    let target = input[3 + 2 * edge]
    if source < 0 or source >= n64 or target < 0 or target >= n64: return -1
    let bit = uint32(1) shl int(target)
    if (adjacency[int(source)] and bit) != 0: return -1
    adjacency[int(source)] = adjacency[int(source)] or bit

  var removed: array[MaxN, bool]
  var sinkDepth: array[MaxN, int]
  var remaining = n
  var depth = 0
  while remaining > 0:
    var sinks: array[MaxN, bool]
    var sinkCount = 0
    for vertex in 0..<n:
      if removed[vertex]: continue
      var hasSuccessor = false
      for target in 0..<n:
        if not removed[target] and (adjacency[vertex] and (uint32(1) shl target)) != 0:
          hasSuccessor = true
          break
      if not hasSuccessor:
        sinks[vertex] = true
        inc sinkCount
    if sinkCount == 0: return -1
    for vertex in 0..<n:
      if sinks[vertex]:
        removed[vertex] = true
        sinkDepth[vertex] = depth
    remaining -= sinkCount
    inc depth

  let outputBytes = 8 * (n + 1)
  if output.isNil or capacity < csize_t(outputBytes): return -2
  for byte in 0..<8: output[byte] = uint8((uint64(depth) shr (8 * byte)) and 255'u64)
  for vertex in 0..<n:
    let layer = uint64(depth - 1 - sinkDepth[vertex])
    for byte in 0..<8: output[(vertex + 1) * 8 + byte] = uint8((layer shr (8 * byte)) and 255'u64)
  int64(outputBytes)
