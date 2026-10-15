proc storeI64Le(output: ptr UncheckedArray[uint8], position: int, value: int64) =
  let bits = uint64(value)
  for byte in 0 ..< 8:
    output[position + byte] = uint8((bits shr (byte * 8)) and 0xFF'u64)

proc fair_share_scheduling*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "fair_share_scheduling".} =
  if values.isNil or length < 3 or length > 323: return -2
  if (values[0] < 0 or values[0] > 64 or values[1] < 0 or values[1] > 128 or
      values[2] < 0 or values[2] > 1_000_000): return -2
  let userCount = int(values[0])
  let taskCount = int(values[1])
  let resources = values[2]
  if int(length) != 3 + userCount + 2 * taskCount: return -2

  var ids: array[64, int64]
  var weights: array[64, int64]
  var order: array[64, int]
  for user in 0 ..< userCount:
    let id = values[3 + user]
    if id < 0 or id > 63: return -2
    for previous in 0 ..< user:
      if ids[previous] == id: return -2
    ids[user] = id
    order[user] = user
  let taskStart = 3 + userCount
  for task in 0 ..< taskCount:
    let owner = values[taskStart + 2 * task]
    let weight = values[taskStart + 2 * task + 1]
    if owner < 0 or owner > 63 or weight < 0 or weight > 1_000_000: return -2
    for user in 0 ..< userCount:
      if ids[user] == owner:
        weights[user] += weight
        break
  for i in 1 ..< userCount:
    let key = order[i]
    var j = i
    while j > 0 and ids[order[j - 1]] > ids[key]:
      order[j] = order[j - 1]
      dec j
    order[j] = key
  var totalWeight = 0'i64
  for user in 0 ..< userCount: totalWeight += weights[user]
  let required = userCount * 24
  if int(outputCapacity) < required or (required != 0 and output.isNil): return -2
  for position in 0 ..< userCount:
    let user = order[position]
    let allocation = if totalWeight == 0: 0'i64 else: weights[user] * resources div totalWeight
    storeI64Le(output, position * 24, ids[user])
    storeI64Le(output, position * 24 + 8, weights[user])
    storeI64Le(output, position * 24 + 16, allocation)
  int64(userCount)
