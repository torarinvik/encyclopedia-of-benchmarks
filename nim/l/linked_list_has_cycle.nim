## Floyd cycle detection over a portable successor-index representation.
const MaxNodes = 100000

proc validSuccessors(next: ptr UncheckedArray[int64], length: csize_t): bool =
  if length > csize_t(MaxNodes) or (length != 0 and next == nil): return false
  var i = csize_t(0)
  while i < length:
    if next[i] < -1 or next[i] >= int64(length): return false
    inc i
  true

proc successor(next: ptr UncheckedArray[int64], node: int64): int64 =
  if node < 0: -1 else: next[int(node)]

## Input entries are next-node indices; -1 means null and node 0 is the head.
proc linked_list_has_cycle*(next: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "linked_list_has_cycle".} =
  if not validSuccessors(next, length): return -1
  if length == 0: return 0
  var slow = 0'i64
  var fast = 0'i64
  while fast >= 0:
    let first = successor(next, fast)
    if first < 0: break
    slow = successor(next, slow)
    fast = successor(next, first)
    if slow == fast: return 1
  0
