proc putI64(output: ptr UncheckedArray[uint8], at: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0..<8: output[at * 8 + b] = uint8((bits shr (8 * b)) and 255)

proc approximate_tandem_squares*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "approximate_tandem_squares".} =
  if input.isNil or length < 2 or length > 34: return -1
  let n0 = input[0]
  let budget = input[1]
  if n0 < 2 or n0 > 32 or budget < 0 or budget > 8 or int(length) != int(n0) + 2: return -1
  let n = int(n0)
  for i in 0..<n:
    if input[2 + i] < 0 or input[2 + i] > 3: return -1
  var records: array[768, int64]
  var count = 0
  for start in 0..<n:
    var period = 1
    while 2 * period <= n - start:
      var mismatches: int64 = 0
      for i in 0..<period:
        if input[2 + start + i] != input[2 + start + period + i]: inc mismatches
      if mismatches <= budget:
        records[3 * count] = int64(start)
        records[3 * count + 1] = int64(period)
        records[3 * count + 2] = mismatches
        inc count
      inc period
  let bytes = 8 * (1 + 3 * count)
  if output.isNil or int(capacity) < bytes: return -2
  putI64(output, 0, int64(count))
  for i in 0..<3 * count: putI64(output, 1 + i, records[i])
  int64(bytes)
