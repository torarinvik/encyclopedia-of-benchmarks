type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]

proc buildPath(target: int, parent: var array[128, int], seen: var array[128, bool],
    queue: var array[128, int], reverse: var array[128, int], path: var array[127, int],
    pathLength: var int): bool =
  if target == 1:
    path[0] = 1
    pathLength = 1
    return true
  var head = 0
  var tail = 1
  queue[0] = 1
  seen[1] = true
  while head < tail:
    let current = queue[head]
    inc head
    var chainLength = 0
    var node = current
    while node != 0:
      reverse[chainLength] = node
      inc chainLength
      node = parent[node]
    for offset in 0..<chainLength:
      let ancestor = reverse[chainLength - offset - 1]
      let child = current + ancestor
      if child > target or seen[child]: continue
      seen[child] = true
      parent[child] = current
      if child == target:
        var count = 0
        node = target
        while node != 0:
          path[count] = node
          inc count
          node = parent[node]
        var left = 0
        var right = count - 1
        while left < right:
          swap(path[left], path[right])
          inc left
          dec right
        pathLength = count
        return true
      queue[tail] = child
      inc tail
  false

proc storeI64Le(output: U8Output, offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8:
    output[csize_t(offset + byte)] = uint8((bits shr (byte * 8)) and 255'u64)

proc knuth_power_tree*(input: I64Input, length: csize_t, output: U8Output,
    outputCapacity: csize_t): int64 {.cdecl, exportc: "knuth_power_tree".} =
  if input == nil or length != 1: return -1
  let targetValue = input[0]
  if targetValue < 1 or targetValue > 127: return -1
  let target = int(targetValue)
  var parent: array[128, int]
  var seen: array[128, bool]
  var queue: array[128, int]
  var reverse: array[128, int]
  var path: array[127, int]
  var pathLength = 0
  if not buildPath(target, parent, seen, queue, reverse, path, pathLength): return -1
  let required = (pathLength + 1) * 8
  if output == nil or outputCapacity < csize_t(required): return -2
  storeI64Le(output, 0, int64(pathLength - 1))
  for index in 0..<pathLength:
    storeI64Le(output, 8 * (index + 1), int64(path[index]))
  int64(required)
