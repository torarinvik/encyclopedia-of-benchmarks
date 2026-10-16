## Check whether two bounded ASCII strings preserve a one-to-one mapping.
const MaxCodepoints = 8
const MaxInputLength = 2 + 2 * MaxCodepoints + 2

proc is_isomorphic*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "is_isomorphic".} =
  if input == nil or length < 2 or length > csize_t(MaxInputLength): return -1
  let source_length = input[0]
  let target_length = input[1]
  if source_length < 0 or source_length > MaxCodepoints or target_length < 0 or target_length > MaxCodepoints:
    return -1
  let source_count = int(source_length)
  let target_count = int(target_length)
  if int(length) != 2 + source_count + target_count: return -1
  for index in 2 ..< int(length):
    if input[index] < 0 or input[index] > 127: return -1
  if source_count != target_count: return 0

  var source_to_target: array[128, int64]
  var target_to_source: array[128, int64]
  for index in 0 ..< 128:
    source_to_target[index] = -1
    target_to_source[index] = -1
  for index in 0 ..< source_count:
    let source = int(input[2 + index])
    let target = int(input[2 + source_count + index])
    if (source_to_target[source] != -1 and source_to_target[source] != int64(target)) or
       (target_to_source[target] != -1 and target_to_source[target] != int64(source)):
      return 0
    source_to_target[source] = int64(target)
    target_to_source[target] = int64(source)
  1
