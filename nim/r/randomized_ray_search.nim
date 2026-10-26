const
  MaxRays = 5
  MaxRounds = 32
  MaxInput = 11

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc randomized_ray_search*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "randomized_ray_search".} =
  if input.isNil or length < csize_t(5) or length > csize_t(MaxInput): return -1
  let raysRaw, growth, initial = input[0], input[1], input[2]
  if raysRaw < 2 or raysRaw > MaxRays or growth < 2 or growth > 4 or initial < 1000
      or initial >= growth * 1000 or int(length) != int(raysRaw) + 5: return -1
  let rays = int(raysRaw)
  var permutation: array[MaxRays, int]
  var seen: array[MaxRays, bool]
  for i in 0 ..< rays:
    let ray = input[3 + i]
    if ray < 0 or ray >= raysRaw: return -1
    let index = int(ray)
    if seen[index]: return -1
    seen[index] = true
    permutation[i] = index
  let target, targetDistance = input[3 + rays], input[4 + rays]
  if target < 0 or target >= raysRaw or targetDistance < 1 or targetDistance > 1_000_000_000: return -1

  var distance = initial
  var total = 0'i64
  var attempts = 0'i64
  var found = false
  for round in 0 ..< MaxRounds:
    let ray = permutation[round mod rays]
    inc attempts
    if int64(ray) == target and targetDistance <= distance:
      total += targetDistance
      found = true
      break
    total += 2 * distance
    distance *= growth
  if not found: return -1
  if output.isNil or capacity < csize_t(16): return -2
  storeI64Le(output, 0, attempts)
  storeI64Le(output, 8, total)
  16
