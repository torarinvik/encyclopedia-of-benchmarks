proc fast_walsh_hadamard_transform*(v: ptr UncheckedArray[int64], length: csize_t,
                                    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "fast_walsh_hadamard_transform".} =
  if v.isNil or length < 2 or length > 130 or (v[0] != 0 and v[0] != 1) or v[1] < 1 or v[1] > 128: return -1
  let n = int(v[1]); if (n and (n - 1)) != 0 or length != csize_t(n + 2): return -1
  var a: array[128, int64]
  for i in 0 ..< n:
    if v[i + 2] < -10000 or v[i + 2] > 10000: return -1
    a[i] = v[i + 2]
  var h = 1
  while h < n:
    var blockStart = 0
    while blockStart < n:
      for j in 0 ..< h:
        let x = a[blockStart + j]; let y = a[blockStart + j + h]
        a[blockStart + j] = x + y; a[blockStart + j + h] = x - y
      blockStart += 2 * h
    h *= 2
  if v[0] == 1:
    for i in 0 ..< n:
      if a[i] mod int64(n) != 0: return -1
      a[i] = a[i] div int64(n)
  if n * 8 > int(capacity) or output.isNil: return -2
  for i in 0 ..< n:
    let value = cast[uint64](a[i])
    for k in 0 ..< 8: output[i * 8 + k] = uint8((value shr (k * 8)) and 255)
  int64(n)
