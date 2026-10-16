const MAX_ITEMS = 8

proc greedy_item_selection_by_value*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "greedy_item_selection_by_value".} =
  if values == nil or length < 2 or length > 18:
    return -1
  let capacity = values[0]
  let countValue = values[1]
  if capacity < 0 or capacity > 1_000_000 or countValue < 0 or countValue > MAX_ITEMS:
    return -1
  let count = int(countValue)
  if length != csize_t(2 + 2 * count):
    return -1
  var itemValues, weights: array[MAX_ITEMS, int64]
  var order: array[MAX_ITEMS, int]
  for index in 0 ..< count:
    itemValues[index] = values[2 + index]
    weights[index] = values[2 + count + index]
    if itemValues[index] < 0 or itemValues[index] > 1_000_000 or weights[index] < 1 or weights[index] > 1_000_000:
      return -1
    order[index] = index
  for index in 1 ..< count:
    let current = order[index]
    var position = index
    while position > 0 and itemValues[order[position - 1]] < itemValues[current]:
      order[position] = order[position - 1]
      dec position
    order[position] = current

  var totalWeight = 0'i64
  var totalValue = 0'i64
  var sequence = 0'u64
  var selected = 0
  for index in 0 ..< count:
    let item = order[index]
    if totalWeight + weights[item] <= capacity:
      sequence = sequence or (uint64(item + 1) shl (4 * selected))
      inc selected
      totalWeight += weights[item]
      totalValue += itemValues[item]
  int64((uint64(totalValue) shl 36) or (uint64(selected) shl 32) or sequence)
