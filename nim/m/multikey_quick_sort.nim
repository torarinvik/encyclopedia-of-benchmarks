const MaxStrings = 32
const MaxStringLength = 16
const MaxInputWords = 1 + MaxStrings * (1 + MaxStringLength)
const MaxParseableInputWords = MaxInputWords + 1
const MaxOutputBytes = 4 * MaxInputWords

type StringRecord = object
  length: int
  bytes: array[MaxStringLength, uint8]

proc charAt(value: StringRecord, depth: int): int =
  if depth < value.length: int(value.bytes[depth]) else: 0
proc median3(a, b, c: int): int =
  if a < b:
    if b < c: return b
    if a < c: return c
    return a
  if b > c: return b
  if a < c: return a
  return c
proc compareFromDepth(left, right: StringRecord, depthValue: int): int =
  var depth = depthValue
  while depth < left.length and depth < right.length and left.bytes[depth] == right.bytes[depth]: inc depth
  let a = charAt(left, depth)
  let b = charAt(right, depth)
  (if a > b: 1 else: 0) - (if a < b: 1 else: 0)
proc insertionSort(values: var array[MaxStrings, StringRecord], lo, hi, depth: int) =
  for i in lo + 1 ..< hi:
    let value = values[i]
    var j = i
    while j > lo and compareFromDepth(values[j - 1], value, depth) > 0:
      values[j] = values[j - 1]
      dec j
    values[j] = value
proc multikeySort(values: var array[MaxStrings, StringRecord], lo, hi, depth: int) =
  let count = hi - lo
  if count < 10:
    insertionSort(values, lo, hi, depth)
    return
  let mid = lo + count div 2
  var pivot: int
  if count > 30:
    let delta = count div 8
    pivot = median3(
      median3(charAt(values[lo], depth), charAt(values[lo + delta], depth), charAt(values[lo + 2 * delta], depth)),
      median3(charAt(values[mid - delta], depth), charAt(values[mid], depth), charAt(values[mid + delta], depth)),
      median3(charAt(values[hi - 1 - 2 * delta], depth), charAt(values[hi - 1 - delta], depth), charAt(values[hi - 1], depth)))
  else:
    pivot = median3(charAt(values[lo], depth), charAt(values[mid], depth), charAt(values[hi - 1], depth))
  var less = lo
  var scan = lo
  var greater = hi
  while scan < greater:
    let key = charAt(values[scan], depth)
    if key < pivot:
      swap(values[less], values[scan])
      inc less
      inc scan
    elif key > pivot:
      dec greater
      swap(values[greater], values[scan])
    else:
      inc scan
  multikeySort(values, lo, less, depth)
  if pivot != 0: multikeySort(values, less, greater, depth + 1)
  multikeySort(values, greater, hi, depth)

proc putI32Le(output: ptr UncheckedArray[uint8], offset: int, value: int32) =
  let bits = cast[uint32](value)
  for byte in 0 ..< 4: output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u32)

proc multikey_quick_sort*(input: ptr UncheckedArray[int32], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "multikey_quick_sort".} =
  if input == nil or length < 1 or length > csize_t(MaxParseableInputWords): return -1
  let countRaw = input[0]
  if countRaw < 0 or countRaw > MaxStrings: return -1
  let count = int(countRaw)
  var values: array[MaxStrings, StringRecord]
  var pos = 1
  for i in 0 ..< count:
    if pos >= int(length) or input[pos] < 0 or input[pos] > MaxStringLength: return -1
    let stringLength = int(input[pos])
    inc pos
    if pos + stringLength > int(length): return -1
    values[i].length = stringLength
    for j in 0 ..< stringLength:
      let byte = input[pos]
      inc pos
      if byte < 1 or byte > 127: return -1
      values[i].bytes[j] = uint8(byte)
  if pos != int(length): return -1
  let bytes = int(length) * 4
  if output == nil or capacity < csize_t(bytes): return -2
  multikeySort(values, 0, count, 0)
  var buffer: array[MaxOutputBytes, uint8]
  var word = 0
  putI32Le(addr buffer[0], word * 4, countRaw); inc word
  for i in 0 ..< count:
    putI32Le(addr buffer[0], word * 4, int32(values[i].length)); inc word
    for j in 0 ..< values[i].length:
      putI32Le(addr buffer[0], word * 4, int32(values[i].bytes[j])); inc word
  for i in 0 ..< bytes: output[i] = buffer[i]
  int64(bytes)
