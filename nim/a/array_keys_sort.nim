type I64Input = ptr UncheckedArray[int64]
type U8Output = ptr UncheckedArray[uint8]

proc storeI64Le(output: U8Output, offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (byte * 8)) and 0xff'u64)

proc compareRows(left, right: array[4, int64], keys: array[4, int], keyCount: int, ascending: bool): int =
  for index in 0 ..< keyCount:
    let field = keys[index] - 1
    if left[field] < right[field]: return (if ascending: -1 else: 1)
    if left[field] > right[field]: return (if ascending: 1 else: -1)
  0

proc array_keys_sort*(values: I64Input, length: csize_t, output: U8Output,
    outputCapacity: csize_t): int64 {.cdecl, exportc: "array_keys_sort".} =
  if values == nil or length < 8 or length > 263: return -1
  let rawCount = values[0]
  let rawKeyCount = values[1]
  let order = values[2]
  if rawCount < 1 or rawCount > 64 or rawKeyCount < 1 or rawKeyCount > 4 or (order != 0 and order != 1): return -1
  let count = int(rawCount)
  let keyCount = int(rawKeyCount)
  if length != csize_t(3 + keyCount + 4 * count): return -1
  var keys: array[4, int]
  for index in 0 ..< keyCount:
    let key = values[3 + index]
    if key < 1 or key > 4: return -1
    for previous in 0 ..< index:
      if key == int64(keys[previous]): return -1
    keys[index] = int(key)
  var rows: array[64, array[4, int64]]
  let rowsStart = 3 + keyCount
  for row in 0 ..< count:
    for column in 0 ..< 4:
      let value = values[rowsStart + row * 4 + column]
      if value < -1000 or value > 1000: return -1
      rows[row][column] = value
  for left in 0 ..< count:
    for right in left + 1 ..< count:
      if compareRows(rows[left], rows[right], keys, keyCount, true) == 0: return -1
  let byteCount = 32 * count
  if output == nil or outputCapacity < csize_t(byteCount): return -2
  for index in 1 ..< count:
    let temporary = rows[index]
    var position = index
    while position > 0 and compareRows(rows[position - 1], temporary, keys, keyCount, order == 1) > 0:
      rows[position] = rows[position - 1]
      dec position
    rows[position] = temporary
  for row in 0 ..< count:
    for column in 0 ..< 4: storeI64Le(output, 8 * (row * 4 + column), rows[row][column])
  int64(byteCount)
