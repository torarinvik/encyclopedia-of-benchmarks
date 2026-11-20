const MaxItems = 16
const MaxCapacity = 32
const MaxInputLength = 19

proc subset_sum_bin_packing*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "subset_sum_bin_packing".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputLength): return -1
  let rawCount = input[0]
  let rawCapacity = input[1]
  if rawCount < 1 or rawCount > MaxItems or rawCapacity < 1 or rawCapacity > MaxCapacity: return -1
  let count = int(rawCount)
  let capacity = int(rawCapacity)
  if length != csize_t(count + 2): return -1

  var remainingSize: array[MaxItems, int64]
  var remainingItem: array[MaxItems, int]
  var assignedBin: array[MaxItems, int64]
  for index in 0 ..< count:
    let size = input[index + 2]
    if size < 1 or size > rawCapacity: return -1
    remainingSize[index] = size
    remainingItem[index] = index

  var remainingCount = count
  var binCount = 0'i64
  while remainingCount > 0:
    var reachable: array[MaxItems + 1, array[MaxCapacity + 1, bool]]
    reachable[remainingCount][0] = true
    var row = remainingCount
    while row > 0:
      dec row
      let size = int(remainingSize[row])
      for sum in 0 .. capacity:
        reachable[row][sum] = reachable[row + 1][sum]
        if sum >= size and reachable[row + 1][sum - size]:
          reachable[row][sum] = true

    var target = capacity
    while target > 0 and not reachable[0][target]: dec target
    var selected: array[MaxItems, bool]
    var needed = target
    for item in 0 ..< remainingCount:
      let size = int(remainingSize[item])
      if size <= needed and reachable[item + 1][needed - size]:
        selected[item] = true
        needed -= size
        assignedBin[remainingItem[item]] = binCount

    var survivors = 0
    for item in 0 ..< remainingCount:
      if not selected[item]:
        remainingSize[survivors] = remainingSize[item]
        remainingItem[survivors] = remainingItem[item]
        inc survivors
    remainingCount = survivors
    inc binCount

  var checksum = binCount * 10000
  for index in 0 ..< count:
    checksum += int64(index + 1) * (assignedBin[index] + 1)
  checksum
