## Uncompiled exact-length walk counting draft.
proc fixed_length_walk_count*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "fixed_length_walk_count".} =
  const modulus = 1_000_000_007'i64
  if input == nil or length < 4 or length > 261: return -1
  let nv = input[0]
  var k = input[1]
  let source = input[2]
  let target = input[3]
  if nv < 1 or nv > 16 or k < 0 or k > 1_000_000_000 or source < 0 or source >= nv or
      target < 0 or target >= nv or length != csize_t(4 + nv*nv): return -1
  let n = int(nv)
  var matrix: array[16, array[16, int64]]
  var vector: array[16, int64]
  for i in 0 ..< n:
    for j in 0 ..< n:
      let value = input[4+i*n+j]
      if value < 0 or value > 100: return -1
      matrix[i][j] = value
  vector[int(source)] = 1
  while k > 0:
    if (k and 1) != 0:
      var next: array[16, int64]
      for i in 0 ..< n:
        for j in 0 ..< n:
          next[j] = (next[j] + vector[i]*matrix[i][j]) mod modulus
      vector = next
    k = k shr 1
    if k > 0:
      var next: array[16, array[16, int64]]
      for i in 0 ..< n:
        for p in 0 ..< n:
          for j in 0 ..< n:
            next[i][j] = (next[i][j] + matrix[i][p]*matrix[p][j]) mod modulus
      matrix = next
  vector[int(target)]
