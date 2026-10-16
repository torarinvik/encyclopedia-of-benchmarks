## Recursively count a finite singly linked chain represented in node order.
proc count_recursive(input: ptr UncheckedArray[int64], index, remaining: int): int64 =
  if remaining == 0: return 0
  let payload = input[index]
  if payload < -2147483648'i64 or payload > 2147483647'i64: return -1
  let tailCount = count_recursive(input, index + 1, remaining - 1)
  if tailCount < 0: return -1
  return 1 + tailCount

proc count_singly_linked_list_recursion*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "count_singly_linked_list_recursion".} =
  const maxNodes = 64
  if input == nil or length < 1 or input[0] < 0 or input[0] > int64(maxNodes):
    return -1
  let count = int(input[0])
  if length != csize_t(count + 1): return -1
  return count_recursive(input, 1, count)
