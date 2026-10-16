proc ones_and_zeros*(values: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "ones_and_zeros".} =
  if values == nil or length < 3: return -1
  let count = values[0]; let zb = values[1]; let ob = values[2]
  if count < 0 or count > 32 or zb < 0 or zb > 32 or ob < 0 or ob > 32 or int(length) != 3+2*int(count): return -1
  var dp: array[33, array[33, int64]]
  for i in 0 ..< int(count):
    let z = values[3+2*i]; let o = values[4+2*i]
    if z < 0 or z > 32 or o < 0 or o > 32: return -1
    for a in countdown(int(zb), int(z)):
      for b in countdown(int(ob), int(o)):
        let candidate = dp[a-int(z)][b-int(o)] + 1
        if candidate > dp[a][b]: dp[a][b] = candidate
  dp[int(zb)][int(ob)]
