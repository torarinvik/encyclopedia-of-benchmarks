type I64Input = ptr UncheckedArray[int64]

func bstShape(start, ending, heapIndex: int): uint64 =
  if start >= ending: return 0'u64
  let middle = start + (ending - start - 1) div 2
  result = (1'u64 shl heapIndex) or
           bstShape(start, middle, 2 * heapIndex + 1) or
           bstShape(middle + 1, ending, 2 * heapIndex + 2)

proc bst_from_sorted_array*(values: I64Input, length: csize_t): int64
    {.cdecl, exportc: "bst_from_sorted_array".} =
  if length > 15 or (length != 0 and values == nil): return -1
  let count = int(length)
  for index in 0 ..< count:
    if values[index] < low(int32).int64 or values[index] > high(int32).int64: return -1
    if index > 0 and values[index - 1] >= values[index]: return -1
  int64(bstShape(0, count, 0))
