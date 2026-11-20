proc putWord(output: ptr UncheckedArray[uint8], at: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0..<8: output[at+b] = uint8((bits shr (8*b)) and 255'u64)

proc k_quadtree_sampled_point_subdivision*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "k_quadtree_sampled_point_subdivision".} =
  if input.isNil or length < 3 or length > 68: return -1
  let nv, kv, dv = input[0], input[1], input[2]
  if nv < 1 or nv > 32 or kv < 1 or kv > nv or dv < 1 or dv > 8: return -1
  let n, k, depth = int(nv), int(kv), int(dv)
  if int(length) != 3+2*n: return -1
  let side = 1 shl depth
  var keys: array[32,uint32]
  for i in 0..<n:
    let x, y = input[3+2*i], input[4+2*i]
    if x < 0 or y < 0 or x >= int64(side) or y >= int64(side): return -1
    var key = 0'u32
    for bit in countdown(depth-1,0):
      key = (key shl 2) or (((cast[uint32](x) shr bit) and 1'u32) shl 1) or ((cast[uint32](y) shr bit) and 1'u32)
    keys[i] = key
  for i in 1..<n:
    let value = keys[i]
    var j = i
    while j > 0 and keys[j-1] > value:
      keys[j] = keys[j-1]
      dec j
    keys[j] = value
  for i in 1..<n:
    if keys[i] == keys[i-1]: return -1
  let samples = (n-1) div k + 1
  var splitDepth: array[31,int]
  var splitPrefix: array[31,uint32]
  var count = 0
  for i in 0..<max(0,samples-1):
    let a, b = keys[i*k], keys[(i+1)*k]
    var common = 0
    while common < depth:
      let shift = 2*(depth-common-1)
      if ((a shr shift) and 3'u32) != ((b shr shift) and 3'u32): break
      inc common
    let prefix = if common == 0: 0'u32 else: a shr (2*(depth-common))
    var j = 0
    while j < count and (splitDepth[j] != common or splitPrefix[j] != prefix): inc j
    if j == count:
      splitDepth[count] = common
      splitPrefix[count] = prefix
      inc count
  for i in 1..<count:
    let d, p = splitDepth[i], splitPrefix[i]
    let start = p shl (2*(depth-d))
    var j = i
    while j > 0:
      let previousStart = splitPrefix[j-1] shl (2*(depth-splitDepth[j-1]))
      if previousStart < start or (previousStart == start and splitDepth[j-1] <= d): break
      splitDepth[j] = splitDepth[j-1]
      splitPrefix[j] = splitPrefix[j-1]
      dec j
    splitDepth[j] = d
    splitPrefix[j] = p
  let outputBytes = 8*(1+2*count)
  if output.isNil or capacity < csize_t(outputBytes): return -2
  putWord(output, 0, int64(count))
  for i in 0..<count:
    putWord(output, 8*(1+2*i), int64(splitDepth[i]))
    putWord(output, 8*(2+2*i), int64(splitPrefix[i]))
  int64(outputBytes)
