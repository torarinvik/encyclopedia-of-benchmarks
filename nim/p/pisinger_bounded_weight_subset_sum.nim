const MaxItems = 32
const MaxTarget = 256'i64
const MaxWeight = 12'i64
const MaxParseableInputLength = 35

proc pisinger_bounded_weight_subset_sum*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "pisinger_bounded_weight_subset_sum".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxParseableInputLength): return -1
  let nValue = input[0]
  let targetValue = input[1]
  if nValue < 0 or nValue > int64(MaxItems) or targetValue < 0 or targetValue > MaxTarget: return -1
  let n = int(nValue)
  if int(length) != n + 2: return -1

  var width = 0'i32
  for index in 0 ..< n:
    let weight = input[index + 2]
    if weight < 1 or weight > MaxWeight: return -1
    if weight > int64(width): width = int32(weight)
  if n == 0: return 0

  let target = int32(targetValue)
  var prefixSum = 0'i32
  var breakIndex = 0
  while breakIndex < n and prefixSum + int32(input[breakIndex + 2]) <= target:
    prefixSum += int32(input[breakIndex + 2])
    inc breakIndex
  if breakIndex == n: return int64(prefixSum)

  var previous: array[2 * int(MaxWeight), int32]
  var current: array[2 * int(MaxWeight), int32]
  for slot in 0 ..< 2 * int(width): previous[slot] = -1
  previous[int(prefixSum + width - target - 1)] = int32(breakIndex)

  for item in breakIndex ..< n:
    for slot in 0 ..< 2 * int(width): current[slot] = previous[slot]
    let weight = int32(input[item + 2])
    for slot in 0 ..< int(width):
      let destination = slot + int(weight)
      if previous[slot] > current[destination]: current[destination] = previous[slot]
    var slot = 2 * int(width) - 1
    while slot >= int(width):
      let firstItem = max(0'i32, previous[slot])
      let stopItem = current[slot]
      var removed = firstItem
      while removed < stopItem:
        let reduced = slot - int(input[int(removed) + 2])
        if removed > current[reduced]: current[reduced] = removed
        inc removed
      dec slot
    for slot in 0 ..< 2 * int(width): previous[slot] = current[slot]

  let lowMass = if target >= width: target - width + 1 else: 0'i32
  var mass = target
  while mass >= lowMass:
    if previous[int(mass + width - target - 1)] >= 0: return int64(mass)
    if mass == lowMass: break
    dec mass
  0
