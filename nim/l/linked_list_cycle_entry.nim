## Floyd cycle-entry search over a portable successor-index representation.
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

## Returns the cycle-entry node index, -1 when acyclic, and -2 for malformed input.
proc linked_list_cycle_entry*(next: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "linked_list_cycle_entry".} =
  if not validSuccessors(next, length): return -2
  if length == 0: return -1
  var slow = 0'i64
  var fast = 0'i64
  var meeting = false
  while fast >= 0:
    let first = successor(next, fast)
    if first < 0: break
    slow = successor(next, slow)
    fast = successor(next, first)
    if slow == fast:
      meeting = true
      break
  if not meeting: return -1
  var entry = 0'i64
  while entry != slow:
    entry = successor(next, entry)
    slow = successor(next, slow)
  entry
