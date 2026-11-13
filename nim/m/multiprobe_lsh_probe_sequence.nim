import std/[algorithm, heapqueue]

type Choice = tuple[distance, coordinate, sign: int]
type Item = tuple[score, count, mask: int]

proc entry(mask: int, choices: seq[Choice]): Item =
  result.mask = mask
  for i, choice in choices:
    if (mask and (1 shl i)) != 0:
      result.score += choice.distance * choice.distance
      inc result.count

proc multiprobe_lsh_probe_sequence*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "multiprobe_lsh_probe_sequence".} =
  if input.isNil or length < 4 or length > 7: return -1
  if input[0] < 1 or input[0] > 4 or input[1] < 1 or input[1] > 1000: return -1
  let m = int(input[0])
  let width = int(input[1])
  var limit = 1
  for i in 0..<m: limit *= 3
  if length != csize_t(3+m) or input[2] < 0 or input[2] >= int64(limit): return -1
  let count = int(input[2])
  var choices: seq[Choice]
  for i in 0..<m:
    if input[3+i] < 0 or input[3+i] > int64(width): return -1
    let low = int(input[3+i])
    choices.add((low, i, -1))
    choices.add((width-low, i, 1))
  choices.sort()
  var heap = initHeapQueue[Item]()
  heap.push(entry(1, choices))
  var staged: array[80, uint8]
  var emitted = 0
  while emitted < count:
    let mask = heap.pop().mask
    var top = 0
    while (1 shl (top+1)) <= mask: inc top
    if top+1 < 2*m:
      heap.push(entry((mask xor (1 shl top)) or (1 shl (top+1)), choices))
      heap.push(entry(mask or (1 shl (top+1)), choices))
    var seen = 0
    var valid = true
    for i, choice in choices:
      if (mask and (1 shl i)) != 0:
        let bit = 1 shl choice.coordinate
        if (seen and bit) != 0:
          valid = false
          break
        seen = seen or bit
    if valid:
      staged[emitted] = uint8(mask)
      inc emitted
  if output.isNil or capacity < csize_t(count): return -2
  for i in 0..<count: output[i] = staged[i]
  int64(count)
