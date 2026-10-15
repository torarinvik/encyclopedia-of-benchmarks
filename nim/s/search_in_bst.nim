const MaxNodeCount = 5000
const MaxValue = 10_000_000'i64

proc search_in_bst*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "search_in_bst".} =
  if input == nil or length < 3: return -1
  let countValue = input[0]
  let root = input[1]
  let target = input[2]
  if countValue < 0 or countValue > MaxNodeCount or
      int(length) != 3 + 3 * int(countValue) or target < 1 or target > MaxValue: return -1
  let count = int(countValue)
  if count == 0: return -1
  if root < 0 or uint64(root) >= uint64(count): return -1
  var node = root
  while node != -1:
    if node < 0 or uint64(node) >= uint64(count): return -1
    let offset = 3 + 3 * int(node)
    let value = input[offset]
    let left = input[offset + 1]
    let right = input[offset + 2]
    if value < 1 or value > MaxValue or left < -1 or right < -1 or
        (left >= 0 and uint64(left) >= uint64(count)) or
        (right >= 0 and uint64(right) >= uint64(count)): return -1
    if value == target: return node
    node = if target < value: left else: right
  return -1
