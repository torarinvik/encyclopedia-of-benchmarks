proc randomPivotQuickSortNext31(state: var uint64): uint64 =
  state = (state * 48271'u64) mod 2147483647'u64
  state

proc randomPivotQuickSortNext(state: var uint64): uint64 =
  let high = randomPivotQuickSortNext31(state)
  let low = randomPivotQuickSortNext31(state)
  high * 2147483647'u64 + low

proc randomPivotQuickSortPartition(values: ptr UncheckedArray[int64], low, high: csize_t, state: var uint64): csize_t =
  let width = high - low
  let pivotIndex = low + csize_t(randomPivotQuickSortNext(state) mod uint64(width))
  let pivotValue = values[pivotIndex]
  swap(values[pivotIndex], values[high - 1])
  var boundary = low
  var scan = low
  while scan < high - 1:
    if values[scan] < pivotValue:
      swap(values[boundary], values[scan])
      inc boundary
    inc scan
  swap(values[boundary], values[high - 1])
  boundary

proc random_pivot_quick_sort*(values: ptr UncheckedArray[int64], length: csize_t) {.cdecl, exportc: "random_pivot_quick_sort".} =
  if length < 2:
    return
  var stackLow: array[128, csize_t]
  var stackHigh: array[128, csize_t]
  var stackSize = csize_t(0)
  var low = csize_t(0)
  var high = length
  var randomState = 1'u64
  while true:
    while high - low > 1:
      let pivot = randomPivotQuickSortPartition(values, low, high, randomState)
      let leftSize = pivot - low
      let rightSize = high - pivot - 1
      if leftSize < rightSize:
        if rightSize > 1:
          stackLow[stackSize] = pivot + 1
          stackHigh[stackSize] = high
          inc stackSize
        high = pivot
      else:
        if leftSize > 1:
          stackLow[stackSize] = low
          stackHigh[stackSize] = pivot
          inc stackSize
        low = pivot + 1
    if stackSize == 0:
      break
    dec stackSize
    low = stackLow[stackSize]
    high = stackHigh[stackSize]
