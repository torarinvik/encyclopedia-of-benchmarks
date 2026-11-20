const MaxLength = 1024

proc insertionSort(values: ptr UncheckedArray[int64], length: csize_t) =
  var index = csize_t(1)
  while index < length:
    let key = values[index]
    var position = index
    while position > 0 and values[position - 1] > key:
      values[position] = values[position - 1]
      dec position
    values[position] = key
    inc index

proc linear_probing_sort*(values: ptr UncheckedArray[int64], length: csize_t)
    {.cdecl, exportc: "linear_probing_sort".} =
  if values == nil or length < 2:
    return
  if length > MaxLength:
    insertionSort(values, length)
    return

  var minimum = values[0]
  var maximum = values[0]
  for index in 0 ..< length:
    if values[index] < 0 or values[index] > 255:
      insertionSort(values, length)
      return
    if values[index] < minimum: minimum = values[index]
    if values[index] > maximum: maximum = values[index]

  let mainSlots = 256 * (length + 1) + 1
  let tableLength = mainSlots + length
  var table = newSeq[int64](int(tableLength))
  let span = maximum - minimum
  for index in 0 ..< length:
    let home = if span == 0: csize_t(0) else:
      csize_t((values[index] - minimum) * int64(mainSlots - 1) div span)
    var slot = home
    while table[int(slot)] != 0:
      inc slot
    table[int(slot)] = values[index] + 1
  var output = csize_t(0)
  for slot in 0 ..< tableLength:
    if table[int(slot)] != 0:
      values[output] = table[int(slot)] - 1
      inc output
