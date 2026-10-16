const MaxLimit = 100_000_000'i64
const HashCapacity = 32768
const HashMask = HashCapacity - 1

proc isPalindrome(value: int64): bool =
  if value mod 10 == 0: return false
  let original = value
  var remaining = value
  var reversed = 0'i64
  while remaining > 0:
    reversed = reversed * 10 + remaining mod 10
    remaining = remaining div 10
  original == reversed

proc insertUnique(seen: var array[HashCapacity, int64], value: int64): bool =
  var slot = int((((uint64(value) * 2_654_435_761'u64) shr 17) and uint64(HashMask)))
  while seen[slot] != 0 and seen[slot] != value:
    slot = (slot + 1) and HashMask
  if seen[slot] == value: return false
  seen[slot] = value
  true

proc problem125*(limit: int64): int64 {.cdecl, exportc: "problem125".} =
  if limit < 0 or limit > MaxLimit: return -1
  var seen: array[HashCapacity, int64]
  var total = 0'i64
  var first = 1'i64
  while true:
    var last = first + 1
    var sum = first * first + last * last
    if sum >= limit: break
    while sum < limit:
      if isPalindrome(sum) and insertUnique(seen, sum): total += sum
      inc last
      sum += last * last
    inc first
  total
