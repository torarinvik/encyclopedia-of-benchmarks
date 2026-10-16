## Enumerate positive value lists in include-first source order.
proc writeI64Le(output: ptr UncheckedArray[uint8], position: ptr int, value: int64) =
  let bits = cast[uint64](value)
  for shift in countup(0, 56, 8):
    output[position[]] = uint8((bits shr shift) and 0xff'u64)
    position[] += 1

proc enumerate(items: ptr UncheckedArray[int64], itemCount, index: int, target, total: int64,
               chosen: var array[11, int64], chosenCount: int,
               output: ptr UncheckedArray[uint8], position: ptr int, emit: bool): int =
  if total == target:
    if emit:
      writeI64Le(output, position, int64(chosenCount))
      for i in 0 ..< chosenCount: writeI64Le(output, position, chosen[i])
    return chosenCount + 1
  if index == itemCount or total > target: return 0
  chosen[chosenCount] = items[index + 1]
  let includeSlots = enumerate(items, itemCount, index + 1, target,
    total + items[index + 1], chosen, chosenCount + 1, output, position, emit)
  let excludeSlots = enumerate(items, itemCount, index + 1, target,
    total, chosen, chosenCount, output, position, emit)
  includeSlots + excludeSlots

proc subset_sum_values_enumeration*(input: ptr UncheckedArray[int64], length: csize_t,
                                    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "subset_sum_values_enumeration".} =
  if input.isNil or length == 0 or length > 12: return -1
  let target = input[0]
  if target < 0 or target > 256: return -1
  let items = int(length) - 1
  for index in 0 ..< items:
    if input[index + 1] < 1 or input[index + 1] > 64: return -1

  var chosen: array[11, int64]
  var dummyPosition = 0
  let slots = enumerate(input, items, 0, target, 0, chosen, 0,
    output, addr dummyPosition, false)
  let required = csize_t(slots) * 8
  if required == 0: return 0
  if output.isNil or outputCapacity < required: return -2
  var position = 0
  discard enumerate(input, items, 0, target, 0, chosen, 0,
    output, addr position, true)
  int64(position)
