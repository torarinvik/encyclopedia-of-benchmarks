## Exact perfect-square check using bounded integer binary search.
proc perfect_square*(input: int64): int64 {.cdecl, exportc: "perfect_square".} =
  if input < 0:
    return 0
  if input < 2:
    return 1
  let number = uint64(input)
  if ((0x0213'u64 shr (number and 15)) and 1) == 0:
    return 0
  var low = 1'u64
  let root_limit = if number <= 0xffffffff'u64: 65535'u64 else: 3037000499'u64
  var high = min(number div 2, root_limit)
  while low <= high:
    let middle = (low + high) shr 1
    let square = middle * middle
    if square == number:
      return 1
    if square < number:
      low = middle + 1
    else:
      high = middle - 1
  0
