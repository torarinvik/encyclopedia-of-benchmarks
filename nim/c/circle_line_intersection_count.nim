const MaxQ = 32
const MaxOutputBytes = 8 * MaxQ

proc writeI64(staged: var array[MaxOutputBytes, uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    staged[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc circle_line_intersection_count*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "circle_line_intersection_count".} =
  if input.isNil or length < 4 or length > 101: return -1
  let centerX = input[0]
  let centerY = input[1]
  let radius = input[2]
  let queryValue = input[3]
  if centerX < -1000 or centerX > 1000 or centerY < -1000 or centerY > 1000 or
      radius < 0 or radius > 1000 or queryValue < 0 or queryValue > MaxQ: return -1
  let queryCount = int(queryValue)
  if int(length) != 4 + 3 * queryCount: return -1

  var aValues: array[MaxQ, int64]
  var bValues: array[MaxQ, int64]
  var cValues: array[MaxQ, int64]
  for query in 0 ..< queryCount:
    let a = input[4 + 3 * query]
    let b = input[5 + 3 * query]
    let c = input[6 + 3 * query]
    if a < -100 or a > 100 or b < -100 or b > 100 or (a == 0 and b == 0) or
        c < -200000 or c > 200000: return -1
    aValues[query] = a
    bValues[query] = b
    cValues[query] = c
  let needed = 8 * queryCount
  if needed > 0 and (output.isNil or int(capacity) < needed): return -2

  var staged: array[MaxOutputBytes, uint8]
  for query in 0 ..< queryCount:
    let a = aValues[query]
    let b = bValues[query]
    let offset = a * centerX + b * centerY + cValues[query]
    let normalSquared = a * a + b * b
    let discriminant = radius * radius * normalSquared - offset * offset
    let count = if discriminant > 0: 2'i64 elif discriminant == 0: 1'i64 else: 0'i64
    writeI64(staged, 8 * query, count)
  for byte in 0 ..< needed: output[byte] = staged[byte]
  int64(needed)
