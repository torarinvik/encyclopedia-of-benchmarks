## Sum LCM(i, n), 1 <= i <= n, using the Euler-totient identity.
proc eulerPhi(value: uint64): uint64 =
  result = value
  var remaining = value
  var factor = 2'u64
  while factor <= remaining div factor:
    if remaining mod factor == 0:
      result -= result div factor
      while remaining mod factor == 0:
        remaining = remaining div factor
    if factor == 2: factor = 3 else: factor += 2
  if remaining > 1:
    result -= result div remaining

proc lcm_sum*(input: int64): int64 {.cdecl, exportc: "lcm_sum".} =
  if input < 1 or input > 65535: return -1
  let n = uint64(input)
  var weightedTotients = 1'u64
  var divisor = 1'u64
  while divisor <= n div divisor:
    if n mod divisor == 0:
      weightedTotients += divisor * eulerPhi(divisor)
      let paired = n div divisor
      if paired != divisor:
        weightedTotients += paired * eulerPhi(paired)
    inc divisor
  int64((weightedTotients * n) div 2)
