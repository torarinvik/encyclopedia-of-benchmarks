const
  MaxItems = 256
  MaxCapacity = 2 * MaxItems
  I32Max = 2_147_483_647'i64

proc findInsertionIndex(data: var array[MaxCapacity, int64],
                        occupied: var array[MaxCapacity, bool],
                        capacity: int, value: int64): int =
  var low = 0
  var high = capacity
  while low < high:
    let middle = low + (high - low) div 2
    var probe = I32Max
    for index in middle ..< capacity:
      if occupied[index]:
        probe = data[index]
        break
    if probe != I32Max and probe <= value: low = middle + 1
    else: high = middle
  low

proc insertAtEnd(data: var array[MaxCapacity, int64],
                 occupied: var array[MaxCapacity, bool],
                 capacity: int, value: int64) =
  let last = capacity - 1
  var left = last - 1
  while left >= 0 and occupied[left]: dec left
  if left < 0: return
  for index in left ..< last: data[index] = data[index + 1]
  occupied[left] = true
  data[last] = value

proc insertValue(data: var array[MaxCapacity, int64],
                 occupied: var array[MaxCapacity, bool],
                 capacity: int, value: int64) =
  let position = findInsertionIndex(data, occupied, capacity, value)
  if position >= capacity:
    insertAtEnd(data, occupied, capacity, value)
    return
  if not occupied[position]:
    data[position] = value
    occupied[position] = true
    return

  var right = position
  while right < capacity and occupied[right]: inc right
  var left = position - 1
  while left >= 0 and occupied[left]: dec left
  let canGoRight = right < capacity
  let canGoLeft = left >= 0
  if canGoRight and (not canGoLeft or right - position <= position - left):
    var index = right
    while index > position:
      data[index] = data[index - 1]
      dec index
    occupied[right] = true
    data[position] = value
  elif canGoLeft:
    let gap = left
    for index in gap ..< position - 1: data[index] = data[index + 1]
    occupied[gap] = true
    data[position - 1] = value

proc library_sort*(values: ptr UncheckedArray[int64], length: csize_t) {.cdecl, exportc: "library_sort".} =
  if length < 2 or length > csize_t(MaxItems) or values.isNil: return
  let n = int(length)
  let capacity = 2 * n
  var data: array[MaxCapacity, int64]
  var temporary: array[MaxItems, int64]
  var occupied: array[MaxCapacity, bool]
  var filled = 1
  var next = 1
  var round = 0
  let middle = capacity div 2
  data[middle] = values[0]
  occupied[middle] = true

  while next < n:
    var batch = 1 shl round
    if batch > n - next: batch = n - next
    for index in 0 ..< batch:
      insertValue(data, occupied, capacity, values[next + index])
      inc filled
    next += batch
    inc round
    if next < n:
      var at = 0
      for index in 0 ..< capacity:
        if occupied[index]:
          temporary[at] = data[index]
          inc at
      for index in 0 ..< capacity: occupied[index] = false
      for index in 0 ..< filled:
        let slot = index * capacity div filled
        data[slot] = temporary[index]
        occupied[slot] = true

  var output = 0
  for index in 0 ..< capacity:
    if occupied[index]:
      values[output] = data[index]
      inc output
