const MaxN = 512
const MaxParseableInputLength = 514
const MaxValue = 1_000_000'i64
const Offset = 1_000_001'i64
const Leonardo = [1, 1, 3, 5, 9, 15, 25, 41, 67, 109, 177, 287, 465, 753, 1219, 1973]

proc trailingZeros(value: uint64): int =
  var current = value
  while (current and 1'u64) == 0'u64:
    current = current shr 1
    inc result

proc sift(values: var array[MaxN, int64], orderArg, rootArg: int) =
  var order = orderArg
  var root = rootArg
  let value = values[root]
  while order > 1:
    let right = root - 1
    let left = root - 1 - Leonardo[order - 2]
    if not (value < values[left]) and not (value < values[right]): break
    if not (values[left] < values[right]):
      values[root] = values[left]
      root = left
      dec order
    else:
      values[root] = values[right]
      root = right
      order -= 2
  values[root] = value

proc trinkle(values: var array[MaxN, int64], pArg: uint64, orderArg, rootArg: int, trustyArg: bool) =
  var p = pArg
  var order = orderArg
  var root = rootArg
  var trusty = trustyArg
  let value = values[root]
  while p != 1'u64:
    let stepson = root - Leonardo[order]
    if not (value < values[stepson]): break
    if not trusty and order > 1:
      let right = root - 1
      let left = root - 1 - Leonardo[order - 2]
      if not (values[right] < values[stepson]) or not (values[left] < values[stepson]): break
    values[root] = values[stepson]
    root = stepson
    let mask = p and not 1'u64
    let shift = trailingZeros(mask)
    p = p shr shift
    order += shift
    trusty = false
  if not trusty:
    values[root] = value
    sift(values, order, root)

proc smoothsort(values: var array[MaxN, int64], length: int) =
  if length < 2: return
  let last = length - 1
  var p = 1'u64
  var pshift = 1
  var head = 0
  while head < last:
    if (p and 3'u64) == 3'u64:
      sift(values, pshift, head)
      p = p shr 2
      pshift += 2
    else:
      if Leonardo[pshift - 1] >= last - head: trinkle(values, p, pshift, head, false)
      else: sift(values, pshift, head)
      if pshift == 1:
        p = p shl 1
        pshift = 0
      else:
        p = p shl (pshift - 1)
        pshift = 1
    p = p or 1'u64
    inc head
  trinkle(values, p, pshift, head, false)
  while pshift != 1 or p != 1'u64:
    if pshift <= 1:
      let mask = p and not 1'u64
      let shift = trailingZeros(mask)
      p = p shr shift
      pshift += shift
    else:
      p = p shl 2
      p = p xor 7'u64
      pshift -= 2
      trinkle(values, p shr 1, pshift + 1, head - Leonardo[pshift] - 1, true)
      trinkle(values, p, pshift, head - 1, true)
    dec head

proc smooth_sort_benchmark*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "smooth_sort_benchmark".} =
  if input.isNil or length < csize_t(1) or length > csize_t(MaxParseableInputLength):
    return -1
  if input[0] < 0 or input[0] > int64(MaxN): return -1
  let count = int(input[0])
  if length != csize_t(count + 1): return -1
  var values: array[MaxN, int64]
  for index in 0 ..< count:
    let value = input[index + 1]
    if value < -MaxValue or value > MaxValue: return -1
    values[index] = value
  smoothsort(values, count)
  var checksum = 0'i64
  for index in 0 ..< count:
    checksum += int64(index + 1) * (values[index] + Offset)
  checksum
