proc compareStrings(input: ptr UncheckedArray[int64], startA, lenA, startB, lenB: int): int =
  let limit = min(lenA, lenB)
  for i in 0 ..< limit:
    if input[startA + i] < input[startB + i]: return -1
    if input[startA + i] > input[startB + i]: return 1
  if lenA < lenB: -1 elif lenA > lenB: 1 else: 0

proc longest_common_prefix*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "longest_common_prefix".} =
  if input.isNil or length < 1 or length > 1041 or input[0] < 0 or input[0] > 16: return -1
  let count = int(input[0])
  var starts, sizes: array[16, int]
  var position = 1
  for i in 0 ..< count:
    if position >= int(length) or input[position] < 0 or input[position] > 64: return -1
    sizes[i] = int(input[position]); inc position
    if sizes[i] > int(length) - position: return -1
    starts[i] = position
    for j in 0 ..< sizes[i]:
      if input[position + j] < 0 or input[position + j] > 127: return -1
    position += sizes[i]
  if position != int(length): return -1
  if count == 0: return 0
  var order: array[16, int]
  for i in 0 ..< count: order[i] = i
  for i in 1 ..< count:
    let value = order[i]
    var j = i
    while j > 0 and compareStrings(input, starts[order[j - 1]], sizes[order[j - 1]], starts[value], sizes[value]) > 0:
      order[j] = order[j - 1]; dec j
    order[j] = value
  let first = order[0]; let last = order[count - 1]
  let limit = min(sizes[first], sizes[last])
  var prefix = 0
  while prefix < limit and input[starts[first] + prefix] == input[starts[last] + prefix]: inc prefix
  if capacity < csize_t(prefix) or (prefix > 0 and output.isNil): return -2
  for i in 0 ..< prefix: output[i] = uint8(input[starts[first] + i])
  int64(prefix)
