const
  MaxTextLength = 32
  MaxInputLength = 34
  PackedFieldWords = 4
  PackedListWords = 2

type
  PackedFields = array[PackedFieldWords, uint64]
  PackedList = array[PackedListWords, uint64]
  InputView = object
    raw: ptr UncheckedArray[int64]
    packed: ptr UncheckedArray[uint64]
    rawLength: int
    rawOffset: int

proc fieldGet(fields: PackedFields, index: int): int =
  let value = int((fields[index div 9] shr ((index mod 9) * 7)) and 127'u64)
  if value == 127: -1 else: value

proc fieldSet(fields: var PackedFields, index, value: int) =
  let wordIndex = index div 9
  let shift = (index mod 9) * 7
  let mask = 127'u64 shl shift
  let encoded = uint64(if value < 0: 127 else: value)
  fields[wordIndex] = (fields[wordIndex] and not mask) or (encoded shl shift)

proc listGet(list: PackedList, index: int): int =
  int((list[index div 10] shr ((index mod 10) * 6)) and 63'u64)

proc listSet(list: var PackedList, index, value: int) =
  let wordIndex = index div 10
  let shift = (index mod 10) * 6
  let mask = 63'u64 shl shift
  list[wordIndex] = (list[wordIndex] and not mask) or (uint64(value) shl shift)

proc bitIsSet(bits: uint64, index: int): bool = ((bits shr index) and 1'u64) != 0

proc bitCount(bits: uint64): int =
  var remaining = bits
  while remaining != 0:
    remaining = remaining and (remaining - 1)
    inc result

proc bitsBelow(bits: uint64, index: int): int =
  if index == 0: return 0
  bitCount(bits and ((1'u64 shl index) - 1))

proc symbolAt(input: InputView, index: int): int =
  if input.raw != nil:
    if index == input.rawLength: return 0
    return int(input.raw[index + input.rawOffset]) + 1
  let wordIndex = index div 10
  let shift = (index mod 10) * 6
  int((input.packed[wordIndex] shr shift) and 63'u64)

proc saGet(output: ptr UncheckedArray[uint8], index: int): int64 =
  var bits = 0'u64
  let offset = index * 8
  for byte in 0 ..< 8:
    bits = bits or (uint64(output[offset + byte]) shl (byte * 8))
  if (bits shr 63) != 0: -1'i64 else: int64(bits)

proc saSet(output: ptr UncheckedArray[uint8], index: int, value: int64) =
  let bits = if value < 0: high(uint64) else: uint64(value)
  let offset = index * 8
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255'u64)

proc buildBuckets(input: InputView, length, upper: int,
                  types: uint64, heads, tails, sStarts: var PackedFields) =
  var counts: PackedFields
  var lCounts: PackedFields
  var prefix = 0
  for index in 0 ..< length:
    let symbol = symbolAt(input, index)
    counts.fieldSet(symbol, counts.fieldGet(symbol) + 1)
    if not bitIsSet(types, index):
      lCounts.fieldSet(symbol, lCounts.fieldGet(symbol) + 1)
  for symbol in 0 .. upper:
    let count = counts.fieldGet(symbol)
    heads.fieldSet(symbol, prefix)
    tails.fieldSet(symbol, prefix + count - 1)
    sStarts.fieldSet(symbol, prefix + lCounts.fieldGet(symbol))
    prefix += count

proc sameLmsSubstring(input: InputView, length: int, types, lms: uint64,
                      left, right: int): bool =
  if left == right: return true
  for offset in 0 ..< length:
    let a = left + offset
    let b = right + offset
    if a >= length or b >= length or symbolAt(input, a) != symbolAt(input, b) or
       bitIsSet(types, a) != bitIsSet(types, b): return false
    if offset > 0 and (bitIsSet(lms, a) or bitIsSet(lms, b)):
      return bitIsSet(lms, a) and bitIsSet(lms, b)
  false

proc induce(input: InputView, length, upper: int, types, lms: uint64,
            seeds: PackedList, seedCount: int, useLmsMask: bool,
            output: ptr UncheckedArray[uint8]) =
  var heads, tails, lCursor, sCursor: PackedFields
  var sStarts: PackedFields
  buildBuckets(input, length, upper, types, heads, tails, sStarts)
  for index in 0 ..< length: saSet(output, index, -1)
  for symbol in 0 .. upper: sCursor.fieldSet(symbol, sStarts.fieldGet(symbol))
  if useLmsMask:
    for position in 0 ..< length:
      if not bitIsSet(lms, position): continue
      let symbol = symbolAt(input, position)
      let slot = sCursor.fieldGet(symbol)
      saSet(output, slot, position.int64)
      sCursor.fieldSet(symbol, slot + 1)
  else:
    for item in 0 ..< seedCount:
      let position = listGet(seeds, item)
      let symbol = symbolAt(input, position)
      let slot = sCursor.fieldGet(symbol)
      saSet(output, slot, position.int64)
      sCursor.fieldSet(symbol, slot + 1)
  for symbol in 0 .. upper:
    lCursor.fieldSet(symbol, heads.fieldGet(symbol))
    sCursor.fieldSet(symbol, tails.fieldGet(symbol) + 1)
  for slot in 0 ..< length:
    let position = saGet(output, slot)
    if position <= 0: continue
    let previous = int(position) - 1
    if bitIsSet(types, previous): continue
    let symbol = symbolAt(input, previous)
    let target = lCursor.fieldGet(symbol)
    saSet(output, target, previous.int64)
    lCursor.fieldSet(symbol, target + 1)
  for slot in countdown(length - 1, 0):
    let position = saGet(output, slot)
    if position <= 0: continue
    let previous = int(position) - 1
    if not bitIsSet(types, previous): continue
    let symbol = symbolAt(input, previous)
    let target = sCursor.fieldGet(symbol) - 1
    saSet(output, target, previous.int64)
    sCursor.fieldSet(symbol, target)

proc saisReadonly(input: InputView, length, upper: int,
                  output: ptr UncheckedArray[uint8]) =
  if length == 0: return
  if length == 1:
    saSet(output, 0, 0)
    return
  if length == 2:
    if symbolAt(input, 0) >= symbolAt(input, 1):
      saSet(output, 0, 1); saSet(output, 1, 0)
    else:
      saSet(output, 0, 0); saSet(output, 1, 1)
    return
  var types = 1'u64 shl (length - 1)
  for index in countdown(length - 2, 0):
    let current = symbolAt(input, index)
    let next = symbolAt(input, index + 1)
    if current < next or (current == next and bitIsSet(types, index + 1)):
      types = types or (1'u64 shl index)
  var lms = 0'u64
  var lmsPositions: PackedList
  var lmsCount = 0
  for index in 1 ..< length:
    if not bitIsSet(types, index - 1) and bitIsSet(types, index):
      lms = lms or (1'u64 shl index)
      lmsPositions.listSet(lmsCount, index)
      inc lmsCount
  var emptySeeds: PackedList
  induce(input, length, upper, types, lms, emptySeeds, 0, true, output)
  var reduced: PackedList
  var name = 0
  var sortedCount = 0
  var previousLms = -1
  for slot in 0 ..< length:
    let candidate = saGet(output, slot)
    if candidate < 0 or not bitIsSet(lms, int(candidate)): continue
    let position = int(candidate)
    if previousLms >= 0 and not sameLmsSubstring(input, length, types, lms, previousLms, position):
      inc name
    reduced.listSet(bitsBelow(lms, position), name)
    previousLms = position
    inc sortedCount
  if sortedCount != lmsCount: return
  if name + 1 == lmsCount:
    for ordinal in 0 ..< lmsCount:
      saSet(output, listGet(reduced, ordinal), ordinal.int64)
  else:
    saisReadonly(InputView(packed: cast[ptr UncheckedArray[uint64]](addr reduced[0])),
                 lmsCount, name, output)
  var orderedLms: PackedList
  for item in 0 ..< lmsCount:
    let ordinal = int(saGet(output, item))
    orderedLms.listSet(item, lmsPositions.listGet(ordinal))
  induce(input, length, upper, types, lms, orderedLms, lmsCount, false, output)

proc suffix_array_inplace_readonly_integer*(values: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "suffix_array_inplace_readonly_integer".} =
  if values == nil or length < 1 or length > csize_t(MaxInputLength): return -1
  let countValue = values[0]
  if countValue < 0 or countValue > int64(MaxTextLength): return -1
  let count = int(countValue)
  if length != csize_t(count + 1): return -1
  for index in 0 ..< count:
    if values[index + 1] < 0 or values[index + 1] >= int64(count): return -1
  let workspaceBytes = csize_t(count + 1) * 8
  let outputBytes = csize_t(count) * 8
  if output == nil or capacity < workspaceBytes: return -2
  let input = InputView(raw: values, rawLength: count, rawOffset: 1)
  saisReadonly(input, count + 1, count, output)
  for index in 0 ..< count:
    let position = saGet(output, index + 1)
    saSet(output, index, position)
  int64(outputBytes)
