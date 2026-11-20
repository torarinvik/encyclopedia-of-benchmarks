const MaxElements = 64
const MaxOperations = 128
const MaxInputLength = 387
const LabelModulus = 2_147_483_648'i64
const LabelRing = 4_294_967_296'i64

proc labelWidth(left, right: int64): int64 =
  var difference = (right - left) mod LabelRing
  if difference < 0: difference += LabelRing
  if difference == 0: return LabelModulus
  if difference > LabelModulus: return difference - LabelModulus
  difference

proc insertAfter(anchor, newId: int, labels: var array[65, int64],
    previous, following: var array[65, int]) =
  var successor = following[anchor]
  if labelWidth(labels[anchor], labels[successor]) <= 1'i64:
    var middle = successor
    var ending = following[middle]
    var required = 3'i64
    while ending != anchor and
        labelWidth(labels[anchor], labels[ending]) <= 4'i64 * labelWidth(labels[anchor], labels[middle]):
      inc required
      ending = following[ending]
      if ending == anchor: break
      inc required
      ending = following[ending]
      middle = following[middle]
    let interval = if ending == anchor: LabelModulus
      else: labelWidth(labels[anchor], labels[ending])
    let spacing = interval div required
    var value = labels[ending]
    var cursor = ending
    while true:
      if cursor == 0:
        value += LabelModulus
        if value >= LabelRing: value -= LabelRing
      cursor = previous[cursor]
      if cursor == anchor: break
      value -= spacing
      if value < 0: value += LabelRing
      labels[cursor] = value

  successor = following[anchor]
  labels[newId] = labels[anchor] + labelWidth(labels[anchor], labels[successor]) div 2
  if labels[newId] >= LabelRing: labels[newId] -= LabelRing
  previous[newId] = anchor
  following[newId] = successor
  following[anchor] = newId
  previous[successor] = newId

proc order_maintenance*(input: ptr UncheckedArray[int64],
    length: csize_t): int64 {.cdecl, exportc: "order_maintenance".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxInputLength): return -1
  let capacityValue = input[0]
  let operationValue = input[1]
  if capacityValue < 0'i64 or capacityValue > int64(MaxElements) or
      operationValue < 0'i64 or operationValue > int64(MaxOperations): return -1
  let capacity = int(capacityValue)
  let operationCount = int(operationValue)
  if length != csize_t(2 + 3 * operationCount): return -1

  var labels: array[65, int64]
  var previous, following: array[65, int]
  var inserted = 0
  var checksum = 0'i64
  for operation in 0..<operationCount:
    let offset = 2 + 3 * operation
    let opcode = input[offset]
    let first = input[offset + 1]
    let second = input[offset + 2]
    if opcode == 0'i64:
      if inserted >= capacity or first < 0'i64 or first > int64(inserted) or
          second != int64(inserted + 1): return -1
      inc inserted
      insertAfter(int(first), inserted, labels, previous, following)
    elif opcode == 1'i64:
      if first < 1'i64 or first > int64(inserted) or second < 1'i64 or
          second > int64(inserted): return -1
      if labels[int(first)] < labels[int(second)]: checksum += int64(operation + 1)
    else:
      return -1
  checksum
