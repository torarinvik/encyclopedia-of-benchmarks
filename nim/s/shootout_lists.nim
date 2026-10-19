const MinRuns = 0'i64
const MaxRuns = 10_000'i64
const ListSize = 100
const NodeCount = 203

type ListNode = object
  value: int32
  next: int
  prev: int

proc initSequence(nodes: var array[NodeCount, ListNode], head, base: int) =
  nodes[head].value = int32(ListSize)
  nodes[head].next = base
  nodes[head].prev = base + ListSize - 1
  for offset in 0 ..< ListSize:
    let item = base + offset
    nodes[item].value = int32(offset + 1)
    nodes[item].prev = if offset == 0: head else: item - 1
    nodes[item].next = if offset + 1 == ListSize: head else: item + 1

proc listLength(nodes: openArray[ListNode], head: int): int32 = nodes[head].value

proc popHead(nodes: var array[NodeCount, ListNode], head: int): int =
  if listLength(nodes, head) == 0: return -1
  let item = nodes[head].next
  let next = nodes[item].next
  nodes[head].next = next
  nodes[next].prev = head
  dec nodes[head].value
  item

proc popTail(nodes: var array[NodeCount, ListNode], head: int): int =
  if listLength(nodes, head) == 0: return -1
  let item = nodes[head].prev
  let prev = nodes[item].prev
  nodes[head].prev = prev
  nodes[prev].next = head
  dec nodes[head].value
  item

proc pushTail(nodes: var array[NodeCount, ListNode], head, item: int) =
  let tail = nodes[head].prev
  nodes[tail].next = item
  nodes[item].next = head
  nodes[head].prev = item
  nodes[item].prev = tail
  inc nodes[head].value

proc reverseList(nodes: var array[NodeCount, ListNode], head: int) =
  var current = head
  while true:
    let oldNext = nodes[current].next
    nodes[current].next = nodes[current].prev
    nodes[current].prev = oldNext
    current = oldNext
    if current == head: break

proc listsEqual(nodes: openArray[ListNode], left, right: int): bool =
  if listLength(nodes, left) != listLength(nodes, right): return false
  var a = nodes[left].next
  var b = nodes[right].next
  while a != left and b != right:
    if nodes[a].value != nodes[b].value: return false
    a = nodes[a].next
    b = nodes[b].next
  a == left and b == right

proc testLists(): bool =
  var nodes: array[NodeCount, ListNode]
  const Original = 0
  const Copied = 101
  const Staging = 202
  initSequence(nodes, Original, 1)
  initSequence(nodes, Copied, 102)
  nodes[Staging] = ListNode(value: 0, next: Staging, prev: Staging)
  if not listsEqual(nodes, Copied, Original): return false
  while listLength(nodes, Copied) > 0:
    let item = popHead(nodes, Copied)
    if item < 0: return false
    pushTail(nodes, Staging, item)
  if listLength(nodes, Copied) != 0: return false
  while listLength(nodes, Staging) > 0:
    let item = popTail(nodes, Staging)
    if item < 0: return false
    pushTail(nodes, Copied, item)
  if listLength(nodes, Staging) != 0: return false
  reverseList(nodes, Original)
  nodes[nodes[Original].next].value == int32(ListSize) and
    nodes[nodes[Original].prev].value == 1 and
    nodes[nodes[Copied].next].value == int32(ListSize) and
    nodes[nodes[Copied].prev].value == 1 and
    listLength(nodes, Original) == int32(ListSize) and
    listsEqual(nodes, Original, Copied)

proc shootout_lists*(runs: int64, output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64 {.cdecl, exportc: "shootout_lists".} =
  if runs < MinRuns or runs > MaxRuns: return -1
  if output.isNil: return -2
  let staged = if runs == 0: "0\n" else: "100\n"
  if outputCapacity < csize_t(staged.len): return -2
  for _ in 0 ..< int(runs):
    if not testLists(): return -1
  for index in 0 ..< staged.len: output[index] = uint8(ord(staged[index]))
  int64(staged.len)
