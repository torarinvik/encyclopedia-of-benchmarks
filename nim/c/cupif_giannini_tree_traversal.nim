proc cupif_giannini_tree_traversal*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "cupif_giannini_tree_traversal".} =
  if input.isNil or length < 2 or length > 3: return -1
  if length != 2: return -1

  let heightValue = input[0]
  let keyValue = input[1]
  if heightValue < 0 or heightValue > 6: return -1
  let height = int(heightValue)
  let leafCount = 1 shl height
  if keyValue < 0 or keyValue >= int64(leafCount): return -1
  if output.isNil or capacity < csize_t(leafCount): return -2

  for count in 0 ..< leafCount:
    let path = uint64(count) xor uint64(keyValue)
    var leafCode = 0'u8
    for depth in 0 ..< height:
      if ((path shr depth) and 1'u64) != 0:
        leafCode = leafCode or uint8(1 shl depth)
    output[count] = leafCode
  int64(leafCount)
