const MaxInputLength = 16_384
const MaxBags = 8_191

proc siftDown(values: var array[8_191, int64], root, finish: int) =
  var current = root
  while current < finish div 2:
    var child = current * 2 + 1
    if child + 1 < finish and values[child] < values[child + 1]:
      inc child
    if values[current] >= values[child]:
      break
    swap(values[current], values[child])
    current = child

proc maximum_bags_with_full_capacity*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "maximum_bags_with_full_capacity".} =
  if length < 2 or length > MaxInputLength or input.isNil: return -1
  var remaining = input[0]
  if remaining < 0 or remaining > 1_000_000_000: return -1
  if input[1] < 0 or input[1] > MaxBags: return -1
  let count = int(input[1])
  if int(length) != 2 + 2 * count: return -1
  var deficits: array[MaxBags, int64]
  for index in 0 ..< count:
    let capacity = input[2 + index]
    let rocks = input[2 + count + index]
    if capacity < 1 or capacity > 100_000 or rocks < 0 or rocks > capacity: return -1
    deficits[index] = capacity - rocks
  var start = count div 2
  while start > 0:
    dec start
    siftDown(deficits, start, count)
  var finish = count
  while finish > 1:
    dec finish
    swap(deficits[0], deficits[finish])
    siftDown(deficits, 0, finish)
  var fullBags = 0'i64
  for index in 0 ..< count:
    if deficits[index] > remaining: break
    remaining -= deficits[index]
    inc fullBags
  fullBags
