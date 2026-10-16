const MaxNodes = 128
const MaxInput = 132

proc nextNode(node, n, cycleTarget: int64): int64 =
  if node < 0: return -1
  if node + 1 < n: return node + 1
  cycleTarget

proc two_pointer_technique*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "two_pointer_technique".} =
  if input.isNil or length < 4 or length > MaxInput: return -1
  let op = input[0]
  let n = input[1]
  let cycleTarget = input[2]
  let k = input[3]
  if n < 0 or n > MaxNodes or length != csize_t(4 + n): return -1
  if (n == 0 and cycleTarget != -1) or (n > 0 and (cycleTarget < -1 or cycleTarget >= n)): return -1
  for i in 0 ..< int(n):
    if input[4 + i] < -1000000 or input[4 + i] > 1000000: return -1

  if op == 0:
    if k != 0: return -1
    var slow = if n == 0: -1'i64 else: 0'i64
    var fast = slow
    while fast != -1:
      slow = nextNode(slow, n, cycleTarget)
      fast = nextNode(fast, n, cycleTarget)
      if fast != -1: fast = nextNode(fast, n, cycleTarget)
      if slow == -1 or fast == -1: break
      if slow == fast: return 1
    return 0
  if op == 1:
    if cycleTarget != -1 or k != 0: return -1
    if n == 0: return -2
    var slow = 0'i64
    var fast = 0'i64
    while fast != -1:
      fast = nextNode(fast, n, cycleTarget)
      if fast == -1: break
      fast = nextNode(fast, n, cycleTarget)
      slow = nextNode(slow, n, cycleTarget)
    return input[4 + int(slow)] + 1000001
  if op == 2:
    if cycleTarget != -1 or k < 1 or k > n: return -1
    var lead = 0'i64
    var lag = 0'i64
    for _ in 0 ..< int(k): lead = nextNode(lead, n, cycleTarget)
    while lead != -1:
      lead = nextNode(lead, n, cycleTarget)
      lag = nextNode(lag, n, cycleTarget)
    return input[4 + int(lag)] + 3000002
  -1
