const
  MaxLength = 8
  InvalidResult = -1'i64

proc permutationSortIsSorted(values: array[MaxLength, int64], length: int): bool =
  for index in 1 ..< length:
    if values[index - 1] > values[index]: return false
  true

proc permutation_sort*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "permutation_sort".} =
  if values.isNil or length < 1 or length > csize_t(MaxLength): return InvalidResult

  var working: array[MaxLength, int64]
  var counters: array[MaxLength, int]
  for index in 0 ..< int(length): working[index] = values[index]

  var checked = 1'i64
  if permutationSortIsSorted(working, int(length)): return checked

  var index = 0
  while index < int(length):
    if counters[index] < index:
      let swapIndex = if index mod 2 == 0: 0 else: counters[index]
      swap(working[swapIndex], working[index])
      inc counters[index]
      inc checked
      if permutationSortIsSorted(working, int(length)): return checked
      index = 0
    else:
      counters[index] = 0
      inc index
  InvalidResult
