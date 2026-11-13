import std/math

proc sparse_supernodal_cholesky*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "sparse_supernodal_cholesky".} =
  if input.isNil or length < 2 or length > 56: return -1
  if input[0] < 1 or input[0] > 8 or input[1] < 1 or input[1] > input[0]: return -1
  let n = int(input[0])
  let count = int(input[1])
  let triangle = n * (n + 1) div 2
  if int(length) != 3 + count + n + triangle: return -1
  var boundaries: array[9, int]
  var masks: array[8, int]
  var slots: array[8, array[8, int]]
  for i in 0 .. count:
    if input[2 + i] < 0 or input[2 + i] > int64(n): return -1
    boundaries[i] = int(input[2 + i])
    if i > 0 and boundaries[i] <= boundaries[i - 1]: return -1
  if boundaries[0] != 0 or boundaries[count] != n: return -1
  for row in 0 ..< n:
    let mask = input[3 + count + row]
    if mask < 0 or mask >= (1'i64 shl (row + 1)) or (mask and (1'i64 shl row)) == 0: return -1
    masks[row] = int(mask)
    for col in 0 ..< n: slots[row][col] = -1
  for col in 0 ..< n:
    for row in col + 1 ..< n:
      if (masks[row] and (1 shl col)) != 0:
        for lower in row + 1 ..< n:
          if (masks[lower] and (1 shl col)) != 0 and (masks[lower] and (1 shl row)) == 0: return -1
  for blockIndex in 0 ..< count:
    let first = boundaries[blockIndex]
    let last = boundaries[blockIndex + 1]
    for row in first ..< last:
      for col in first ..< row:
        if (masks[row] and (1 shl col)) == 0: return -1
    let blockMask = ((1 shl last) - 1) xor ((1 shl first) - 1)
    for row in last ..< n:
      let selected = masks[row] and blockMask
      if selected != 0 and selected != blockMask: return -1
  var sparse: array[36, float64]
  var cursor = 3 + count + n
  var used = 0
  for row in 0 ..< n:
    for col in 0 .. row:
      let value = input[cursor]
      inc cursor
      if value < -1_000_000 or value > 1_000_000: return -1
      if (masks[row] and (1 shl col)) == 0:
        if value != 0: return -1
      else:
        slots[row][col] = used
        sparse[used] = float64(value) / 1000.0
        inc used
  for blockIndex in 0 ..< count:
    let first = boundaries[blockIndex]
    let last = boundaries[blockIndex + 1]
    for col in first ..< last:
      let diagonal = slots[col][col]
      let pivot = sparse[diagonal]
      if pivot <= 0.0 or classify(pivot) in {fcNan, fcInf, fcNegInf}: return -1
      sparse[diagonal] = sqrt(pivot)
      for row in col + 1 ..< last: sparse[slots[row][col]] /= sparse[diagonal]
      for row in col + 1 ..< last:
        for target in col + 1 .. row:
          sparse[slots[row][target]] -= sparse[slots[row][col]] * sparse[slots[target][col]]
    for row in last ..< n:
      if (masks[row] and (1 shl first)) != 0:
        for col in first ..< last:
          var value = sparse[slots[row][col]]
          for k in first ..< col: value -= sparse[slots[row][k]] * sparse[slots[col][k]]
          sparse[slots[row][col]] = value / sparse[slots[col][col]]
    for row in last ..< n:
      if (masks[row] and (1 shl first)) != 0:
        for target in last .. row:
          if (masks[target] and (1 shl first)) != 0:
            for k in first ..< last:
              sparse[slots[row][target]] -= sparse[slots[row][k]] * sparse[slots[target][k]]
  let required = 8 * triangle
  if output.isNil or capacity < csize_t(required): return -2
  var offset = 0
  for row in 0 ..< n:
    for col in 0 .. row:
      let value = if slots[row][col] < 0: 0.0 else: sparse[slots[row][col]]
      let bits = cast[uint64](value)
      for byte in 0 ..< 8:
        output[offset] = uint8((bits shr (8 * byte)) and 255'u64)
        inc offset
  int64(required)
