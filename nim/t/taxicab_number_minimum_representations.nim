type TaxicabNode = object
  sum: int32
  a: int32
  b: int32

const MaxRoot = 444
const MaxParseableLength = 2

proc nodeLess(left, right: TaxicabNode): bool =
  if left.sum != right.sum: return left.sum < right.sum
  if left.a != right.a: return left.a < right.a
  return left.b < right.b

proc heapPush(heap: var array[MaxRoot, TaxicabNode], size: var int, node: TaxicabNode) =
  var index = size
  inc size
  while index > 0:
    let parent = (index - 1) div 2
    if not nodeLess(node, heap[parent]): break
    heap[index] = heap[parent]
    index = parent
  heap[index] = node

proc heapPop(heap: var array[MaxRoot, TaxicabNode], size: var int): TaxicabNode =
  result = heap[0]
  dec size
  if size == 0: return
  let last = heap[size]
  var index = 0
  while 2 * index + 1 < size:
    var child = 2 * index + 1
    if child + 1 < size and nodeLess(heap[child + 1], heap[child]): inc child
    if not nodeLess(heap[child], last): break
    heap[index] = heap[child]
    index = child
  heap[index] = last

proc cube(value: int32): int32 = value * value * value

proc search(ways: int32): int64 =
  var heap: array[MaxRoot, TaxicabNode]
  var size = 0
  for a in 1 .. MaxRoot:
    let root = int32(a)
    let value = cube(root)
    heapPush(heap, size, TaxicabNode(sum: 2 * value, a: root, b: root))
  while size > 0:
    let first = heapPop(heap, size)
    let total = first.sum
    var count = 1'i32
    if first.b < int32(MaxRoot):
      let nextB = first.b + 1
      heapPush(heap, size, TaxicabNode(sum: cube(first.a) + cube(nextB), a: first.a, b: nextB))
    while size > 0 and heap[0].sum == total:
      let equal = heapPop(heap, size)
      inc count
      if equal.b < int32(MaxRoot):
        let nextB = equal.b + 1
        heapPush(heap, size, TaxicabNode(sum: cube(equal.a) + cube(nextB), a: equal.a, b: nextB))
    if count >= ways: return int64(total)
  -1

proc taxicab_number_minimum_representations*(input: ptr UncheckedArray[int64],
    length: csize_t): int64 {.cdecl, exportc: "taxicab_number_minimum_representations".} =
  if input.isNil or length < 1 or length > csize_t(MaxParseableLength): return -1
  if length != 1 or (input[0] != 2 and input[0] != 3): return -1
  search(int32(input[0]))
