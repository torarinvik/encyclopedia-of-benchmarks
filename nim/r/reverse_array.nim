proc reverse_array*(input: ptr UncheckedArray[int64], length: csize_t,
                    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "reverse_array".} =
  if length < 1 or length > 257: return -1
  let count = input[0]
  if count < 1 or count > 256 or length != csize_t(count + 1): return -1
  for i in 0 ..< int(count):
    if input[i + 1] < 0 or input[i + 1] > 255: return -1
  if capacity < csize_t(count): return -2
  for i in 0 ..< int(count): output[i] = uint8(input[i + 1])
  var left = 0
  var right = int(count) - 1
  while left < right:
    swap(output[left], output[right])
    inc left
    dec right
  count
