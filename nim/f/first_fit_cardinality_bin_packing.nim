proc putI64(output: ptr UncheckedArray[uint8], at: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0..<8: output[at * 8 + b] = uint8((bits shr (8 * b)) and 255)

proc first_fit_cardinality_bin_packing*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "first_fit_cardinality_bin_packing".} =
  if input.isNil or length < 4 or length > 35: return -1
  let n0 = input[0]; let limit = input[1]; let cap = input[2]
  if n0 < 1 or n0 > 32 or limit < 1 or limit > 32 or cap < 1 or cap > 10000 or int(length) != int(n0) + 3: return -1
  let n = int(n0)
  for i in 0..<n:
    if input[3+i] < 1 or input[3+i] > cap: return -1
  var loads, used, owners: array[32, int64]
  var bins = 0
  for i in 0..<n:
    let size = input[3+i]
    var b = 0
    while b < bins and (used[b] >= limit or loads[b] > cap - size): inc b
    if b == bins: inc bins
    loads[b] += size; inc used[b]; owners[i] = int64(b)
  let bytes = 8 * (n + 1)
  if output.isNil or int(capacity) < bytes: return -2
  putI64(output, 0, int64(bins))
  for i in 0..<n: putI64(output, i+1, owners[i])
  int64(bytes)
