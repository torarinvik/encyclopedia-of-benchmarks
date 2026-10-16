const MaxItems = 12

proc put32(output: ptr UncheckedArray[uint8], pos: var int, value: uint32) =
  var bits = value
  for _ in 0 ..< 4:
    output[pos] = uint8(bits and 255)
    inc pos
    bits = bits shr 8

proc emitSubsets(input: ptr UncheckedArray[int64], n, index: int, mask: uint32,
                 selected: uint32, output: ptr UncheckedArray[uint8], pos: var int) =
  if index == n:
    put32(output, pos, selected)
    for i in 0 ..< n:
      if (mask and (1'u32 shl i)) != 0:
        output[pos] = uint8(input[i + 1])
        inc pos
    return
  emitSubsets(input, n, index + 1, mask or (1'u32 shl index), selected + 1, output, pos)
  emitSubsets(input, n, index + 1, mask, selected, output, pos)

proc generate_subsets_recursive*(input: ptr UncheckedArray[int64], length: csize_t,
                                output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "generate_subsets_recursive".} =
  if input == nil or length < 1 or length > MaxItems + 1: return -1
  let nArg = input[0]
  if nArg < 0 or nArg > MaxItems: return -1
  let n = int(nArg)
  if length != csize_t(n + 1): return -1
  for i in 0 ..< n:
    if input[i + 1] < 0 or input[i + 1] > 127: return -1
  let subsets = 1 shl n
  let needed = 4 + 4 * subsets + n * (subsets div 2)
  if output == nil or capacity < csize_t(needed): return -2
  var pos = 0
  put32(output, pos, uint32(subsets))
  emitSubsets(input, n, 0, 0, 0, output, pos)
  int64(pos)
