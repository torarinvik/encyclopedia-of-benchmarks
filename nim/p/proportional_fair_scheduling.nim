proc storeI64Le(output: ptr UncheckedArray[uint8], position: int, value: int64) =
  let bits = uint64(value)
  for byte in 0 ..< 8:
    output[position + byte] = uint8((bits shr (byte * 8)) and 0xFF'u64)

proc proportional_fair_scheduling*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "proportional_fair_scheduling".} =
  if values.isNil or length < 2 or length > 131: return -1
  if values[0] < 0 or values[0] > 64 or values[1] < 1 or values[1] > 1_000_000: return -1
  let processCount = int(values[0])
  let totalResources = values[1]
  if int(length) != 2 + 2 * processCount: return -1

  var nameIds: array[64, int64]
  var weights: array[64, int64]
  var totalWeight = 0'i64
  for process in 0 ..< processCount:
    let nameId = values[2 + 2 * process]
    let weight = values[3 + 2 * process]
    if nameId < int64(low(int32)) or nameId > int64(high(int32)) or weight < 1 or weight > 1_000_000: return -1
    nameIds[process] = nameId
    weights[process] = weight
    totalWeight += weight

  if processCount == 0: return 0
  let required = processCount * 16
  if output.isNil or int(outputCapacity) < required: return -2
  for process in 0 ..< processCount:
    let quotient = float64(weights[process]) / float64(totalWeight)
    let share = quotient * float64(totalResources)
    let allocation = int32(share)
    storeI64Le(output, process * 16, nameIds[process])
    storeI64Le(output, process * 16 + 8, int64(allocation))
  int64(required)
