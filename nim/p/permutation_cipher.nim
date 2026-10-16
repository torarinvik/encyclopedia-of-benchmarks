proc permutation_cipher*(v: ptr UncheckedArray[int64], n: csize_t): int64 {.cdecl, exportc: "permutation_cipher".} =
  if v.isNil or n < 2 or n > 74 or v[0] < 0 or v[0] > 64: return -1
  let length = int(v[0]); if int(n) < length + 2: return -1
  let kp = length + 1; if v[kp] < 1 or v[kp] > 8: return -1
  let k = int(v[kp]); if int(n) != kp + k + 1: return -1
  var seen: array[8, bool]
  for i in 0..<k:
    let x = v[kp + 1 + i]; if x < 1 or x > int64(k) or seen[int(x - 1)]: return -1
    seen[int(x - 1)] = true
  var t: array[128, byte]; var m = 0
  for i in 0..<length:
    let x = v[i + 1]; if x < 0 or x > 127: return -1
    var c = int(x); if c in [32,9,10,11,12,13]: continue
    if c >= 97 and c <= 122: c -= 32
    t[m] = byte(c); inc m
  while m mod k != 0: t[m] = byte('X'); inc m
  var h = 0'i64; var b = 0
  while b < m:
    for j in 0..<k: h = (h * 257 + int64(t[b + int(v[kp + 1 + j] - 1)])) mod 1000000007
    b += k
  h

