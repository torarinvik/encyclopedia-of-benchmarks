## Count vertex-simple directed paths with recursive DFS.
proc countFrom(values: ptr UncheckedArray[int64], n, current, destination: uint32, visited: uint32): uint32 =
  if current == destination: return 1
  let mask = 1'u32 shl current
  let seen = visited or mask
  var count = 0'u32
  for next in 0'u32 ..< n:
    if values[3 + int(current * n + next)] == 1 and (seen and (1'u32 shl next)) == 0:
      count += countFrom(values, n, next, destination, seen)
  count

proc number_of_paths*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "number_of_paths".} =
  if values == nil or length < 3 or values[0] < 1 or values[0] > 10: return -1
  let n = uint32(values[0])
  if length != csize_t(3 + n * n): return -1
  if values[1] < 0 or values[1] > int64(high(uint32)) or values[2] < 0 or values[2] > int64(high(uint32)):
    return -1
  for i in 3 ..< int(length):
    if values[i] != 0 and values[i] != 1: return -1
  let source = uint32(values[1])
  let destination = uint32(values[2])
  if source >= n or destination >= n: return 0
  int64(countFrom(values, n, source, destination, 0))
