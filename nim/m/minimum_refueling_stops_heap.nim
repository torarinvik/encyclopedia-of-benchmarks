## Greedy minimum refueling stops using a bounded max-heap.
proc minimum_refueling_stops_heap*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "minimum_refueling_stops_heap".} =
  if input.isNil or length < 3 or length > 20: return -2
  let target = input[0]
  let startFuel = input[1]
  let countValue = input[2]
  if target < 1 or target > 2000 or startFuel < 0 or startFuel > 2000 or countValue < 0 or countValue > 8: return -2
  let count = int(countValue)
  if length != csize_t(3 + 2 * count): return -2
  var previous = 0'i64
  for i in 0 ..< count:
    let position = input[3 + 2 * i]
    let fuel = input[4 + 2 * i]
    if position <= previous or position >= target or fuel < 1 or fuel > 2000: return -2
    previous = position

  var heap: array[8, int64]
  var heapLength = 0
  var nextStation = 0
  var reach = startFuel
  var stops = 0'i64
  while reach < target:
    while nextStation < count and input[3 + 2 * nextStation] <= reach:
      var child = heapLength
      inc heapLength
      heap[child] = input[4 + 2 * nextStation]
      while child > 0:
        let parent = (child - 1) div 2
        if heap[parent] >= heap[child]: break
        swap(heap[parent], heap[child])
        child = parent
      inc nextStation
    if heapLength == 0: return -1
    let maximum = heap[0]
    dec heapLength
    if heapLength > 0:
      heap[0] = heap[heapLength]
      var parent = 0
      while true:
        let left = 2 * parent + 1
        let right = left + 1
        if left >= heapLength: break
        var child = left
        if right < heapLength and heap[right] > heap[left]: child = right
        if heap[parent] >= heap[child]: break
        swap(heap[parent], heap[child])
        parent = child
    reach += maximum
    inc stops
  stops
