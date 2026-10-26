proc fibonacci_integer_code*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "fibonacci_integer_code".} =
  if input.isNil or length < 2 or length > 33: return -1
  let n0 = input[0]
  if n0 < 1 or n0 > 32 or int(length) != int(n0) + 1: return -1
  let n = int(n0)
  for i in 0..<n:
    if input[i+1] < 0 or input[i+1] > 1000000: return -1
  var fib: array[30, uint64]
  fib[0] = 1; fib[1] = 2
  var fibCount = 2
  while fibCount < 30 and fib[fibCount-1] + fib[fibCount-2] <= 1000001:
    fib[fibCount] = fib[fibCount-1] + fib[fibCount-2]
    inc fibCount
  var staged: array[960, uint8]
  var out = 0
  for v in 0..<n:
    var remaining = uint64(input[v+1]) + 1
    var top = 0
    while top + 1 < fibCount and fib[top+1] <= remaining: inc top
    var bits: array[30, uint8]
    var j = top + 1
    while j > 0:
      dec j
      if fib[j] <= remaining:
        bits[j] = 1
        remaining -= fib[j]
    for i in 0..top:
      staged[out] = uint8(48) + bits[i]
      inc out
    staged[out] = 49
    inc out
  if output.isNil or int(capacity) < out: return -2
  for i in 0..<out: output[i] = staged[i]
  int64(out)
