## Return the second middle node's index in a successor-index list.
const MaxNodes = 100000

proc middle_of_linked_list*(next: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "middle_of_linked_list".} =
  if length > csize_t(MaxNodes) or (length != 0 and next == nil): return -2
  for index in 0 ..< int(length):
    if next[index] < -1 or next[index] >= int64(length): return -2
  if length == 0: return -1

  var slow = 0'i64
  var fast = 0'i64
  while fast >= 0:
    let first = next[int(fast)]
    if first < 0: break
    slow = next[int(slow)]
    fast = next[int(first)]
    if slow == fast: return -2

  slow = 0
  fast = 0
  while fast >= 0:
    let first = next[int(fast)]
    if first < 0: break
    slow = next[int(slow)]
    fast = next[int(first)]
  slow
