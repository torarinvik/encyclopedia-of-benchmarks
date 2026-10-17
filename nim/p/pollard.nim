const MinN = 2'i64
const MaxN = 111_155'i64

proc nextValue(n, x: int64): int64 =
  (x * x + 1) mod n

proc gcdNonnegative(leftValue, rightValue: int64): int64 =
  var left = leftValue
  var right = rightValue
  while right != 0:
    let remainder = left mod right
    left = right
    right = remainder
  left

proc pollard*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "pollard".} =
  if input == nil or length != 1: return -1
  let n = input[0]
  if n < MinN or n > MaxN: return -1

  var x = 2'i64
  var y = 2'i64
  var divisor = 1'i64
  while divisor == 1:
    x = nextValue(n, x)
    y = nextValue(n, nextValue(n, y))
    var difference = x - y
    if difference < 0: difference = -difference
    divisor = gcdNonnegative(difference, n)
  if divisor == n: 0 else: divisor
