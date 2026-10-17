const
  MinCapacity = 5
  MaxCapacity = 31
  MaxInsertCount = 3
  MaxParseableInputLength = 5
  MaxOutputBytes = 256

proc quadratic_probing*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64 {.cdecl, exportc: "quadratic_probing".} =
  if input == nil or inputLength < 2 or inputLength > MaxParseableInputLength.csize_t:
    return -1
  let capacityValue = input[0]
  let countValue = input[1]
  if capacityValue < MinCapacity.int64 or capacityValue > MaxCapacity.int64 or countValue < 0 or countValue > MaxInsertCount.int64:
    return -1
  let capacity = int(capacityValue)
  let insertCount = int(countValue)
  if inputLength != (2 + insertCount).csize_t:
    return -1
  for index in 0 ..< insertCount:
    if input[index + 2] < 0:
      return -1

  var slots: array[MaxCapacity, int64]
  for index in 0 ..< MaxCapacity:
    slots[index] = -1
  for keyIndex in 0 ..< insertCount:
    let key = input[keyIndex + 2]
    let home = int(key mod int64(capacity))
    if slots[home] == -1:
      slots[home] = key
      continue
    if slots[home] == key:
      continue
    var visited: array[MaxCapacity, bool]
    var probe = 1
    while true:
      let slot = (home + probe * probe) mod capacity
      if slots[slot] == -1 or slots[slot] == int64(home):
        slots[slot] = key
        break
      if visited[slot]:
        return -1
      visited[slot] = true
      inc probe

  let byteLength = 8 * (capacity + 1)
  if byteLength > MaxOutputBytes or output == nil or outputCapacity < byteLength.csize_t:
    return -2
  var words: array[MaxCapacity + 1, int64]
  words[0] = int64(capacity)
  for index in 0 ..< capacity:
    words[index + 1] = slots[index]
  for wordIndex in 0 .. capacity:
    let bits = cast[uint64](words[wordIndex])
    for byteIndex in 0 .. 7:
      output[wordIndex * 8 + byteIndex] = uint8((bits shr (8 * byteIndex)) and 255'u64)
  return int64(byteLength)
