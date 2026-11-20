import std/ffi

const MaxItems = 1024
const NoNode = uint32(MaxItems)

type NodeTable = array[MaxItems, uint32]

proc pileLess(values: ptr UncheckedArray[int64], pileFront: openArray[uint32],
              left, right: uint32): bool =
  let leftNode = int(pileFront[int(left)])
  let rightNode = int(pileFront[int(right)])
  if values[leftNode] != values[rightNode]:
    return values[leftNode] < values[rightNode]
  return left < right

proc siftDown(values: ptr UncheckedArray[int64], pileFront: openArray[uint32],
              heap: var NodeTable, heapSize, start: uint32) =
  var position = start
  while position * 2 + 1 < heapSize:
    var child = position * 2 + 1
    if child + 1 < heapSize and pileLess(values, pileFront, heap[int(child + 1)], heap[int(child)]):
      inc child
    if not pileLess(values, pileFront, heap[int(child)], heap[int(position)]):
      break
    swap(heap[int(position)], heap[int(child)])
    position = child

proc unshuffle_sort*(values, scratch: ptr UncheckedArray[int64], length: csize_t)
    {.cdecl, exportc: "unshuffle_sort".} =
  if values.isNil or scratch.isNil or length < csize_t(2) or length > csize_t(MaxItems):
    return
  let n = int(length)
  var previous, next, pileFront, pileBack, heap: NodeTable
  var pileCount = 0'u32

  for node in 0 ..< n:
    previous[node] = NoNode
    next[node] = NoNode
    var pile = 0'u32
    while pile < pileCount:
      let front = int(pileFront[int(pile)])
      let back = int(pileBack[int(pile)])
      if values[node] <= values[front]:
        next[node] = pileFront[int(pile)]
        previous[front] = uint32(node)
        pileFront[int(pile)] = uint32(node)
        break
      if values[node] >= values[back]:
        previous[node] = pileBack[int(pile)]
        next[back] = uint32(node)
        pileBack[int(pile)] = uint32(node)
        break
      inc pile
    if pile == pileCount:
      pileFront[int(pileCount)] = uint32(node)
      pileBack[int(pileCount)] = uint32(node)
      inc pileCount

  var heapSize = 0'u32
  for pile in 0'u32 ..< pileCount:
    var position = heapSize
    heap[int(position)] = pile
    inc heapSize
    while position > 0:
      let parent = (position - 1) div 2
      if not pileLess(values, pileFront, heap[int(position)], heap[int(parent)]):
        break
      swap(heap[int(position)], heap[int(parent)])
      position = parent

  var output = 0
  while heapSize > 0:
    let pile = int(heap[0])
    let node = int(pileFront[pile])
    scratch[output] = values[node]
    inc output
    let successor = next[node]
    if successor != NoNode:
      previous[int(successor)] = NoNode
      next[node] = NoNode
      pileFront[pile] = successor
    else:
      pileFront[pile] = NoNode
      pileBack[pile] = NoNode
      dec heapSize
      if heapSize > 0:
        heap[0] = heap[int(heapSize)]
    if heapSize > 0:
      siftDown(values, pileFront, heap, heapSize, 0)

  for index in 0 ..< n:
    values[index] = scratch[index]
