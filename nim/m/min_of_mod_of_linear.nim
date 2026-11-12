type
  I64Input = ptr UncheckedArray[int64]

proc floorSum(nInput, mInput, aInput, bInput: int64): int64 =
  var n = nInput
  var m = mInput
  var a = aInput
  var b = bInput
  var answer = 0'i64
  while true:
    if a >= m:
      let quotient = a div m
      var left = n
      var right = n - 1
      if left mod 2 == 0: left = left div 2
      else: right = right div 2
      answer += left * right * quotient
      a = a mod m
    if b >= m:
      answer += n * (b div m)
      b = b mod m
    let numerator = a * n + b
    let height = numerator div m
    if height == 0: return answer
    b = numerator mod m
    n = height
    swap(m, a)

proc min_of_mod_of_linear*(input: I64Input, length: csize_t): int64 {.cdecl, exportc: "min_of_mod_of_linear".} =
  const MaxParameter = 1_000_000_000'i64
  if input == nil or length != csize_t(4): return -1
  let n = input[0]
  let m = input[1]
  let a = input[2]
  let b = input[3]
  if n < 1 or n > MaxParameter or m < 1 or m > MaxParameter: return -1
  if a < 0 or a >= m or b < 0 or b >= m: return -1
  let target = floorSum(n, m, a, b) + n
  var low = -1'i64
  var high = m - 1
  while high - low > 1:
    let candidate = low + (high - low) div 2
    let shift = m - 1 - candidate
    if floorSum(n, m, a, b + shift) < target: high = candidate
    else: low = candidate
  high
