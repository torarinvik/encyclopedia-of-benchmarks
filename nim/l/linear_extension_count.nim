const
  MaxN = 12
  MaxLength = 14
  MaxStates = 4096

proc linear_extension_count*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "linear_extension_count".} =
  if input == nil or length < 1 or length > csize_t(MaxLength): return -1
  if input[0] < 0 or input[0] > int64(MaxN): return -1
  let n = int(input[0])
  if int(length) != n+1: return -1
  let full = (1 shl n)-1
  var predecessor: array[MaxN, int]
  for vertex in 0 ..< n:
    if input[1+vertex] < 0 or input[1+vertex] > int64(full): return -1
    predecessor[vertex] = int(input[1+vertex])
  var ways: array[MaxStates, int64]
  ways[0] = 1
  for prefix in 0 .. full:
    let count = ways[prefix]
    if count == 0: continue
    for vertex in 0 ..< n:
      let bit = 1 shl vertex
      if (prefix and bit) == 0 and (predecessor[vertex] and prefix) == predecessor[vertex]:
        ways[prefix or bit] += count
  ways[full]
