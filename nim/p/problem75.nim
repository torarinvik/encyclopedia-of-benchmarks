const MaxLimit = 1_500_000

proc gcdI64(leftInput, rightInput: int64): int64 =
  var left = leftInput
  var right = rightInput
  while right != 0:
    let remainder = left mod right
    left = right
    right = remainder
  left

proc problem75*(limit: int64): int64 {.cdecl, exportc: "problem75".} =
  if limit > MaxLimit: return -1
  if limit < 0: return 0
  let bound = int(limit)
  var frequency = newSeq[uint8](bound + 1)
  var m = 2'i64
  while 2 * m * (m + 1) <= limit:
    var n = (m mod 2) + 1
    while n < m:
      if gcdI64(m, n) == 1:
        let primitivePerimeter = 2 * m * (m + n)
        var perimeter = primitivePerimeter
        while perimeter <= limit:
          let index = int(perimeter)
          if frequency[index] < 2: inc frequency[index]
          perimeter += primitivePerimeter
      n += 2
    inc m
  var unique = 0'i64
  for perimeter in 1..bound:
    if frequency[perimeter] == 1: inc unique
  unique
