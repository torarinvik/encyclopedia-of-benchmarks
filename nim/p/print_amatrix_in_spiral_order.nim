proc print_amatrix_in_spiral_order*(v: ptr int64, n: uint64): int64 {.cdecl, exportc: "print_amatrix_in_spiral_order".} =
  if v == nil or n < 3 or n > 66 or v[0] < 1 or v[0] > 8 or v[1] < 1 or v[1] > 8 or n != 2'u64 + uint64(v[0] * v[1]): return -1
  let rows = int(v[0]); let cols = int(v[1])
  for i in 2 ..< int(n):
    if v[i] < low(int32).int64 or v[i] > high(int32).int64: return -1
  var top = 0; var bottom = rows - 1; var left = 0; var right = cols - 1
  var h = 2166136261'u32
  proc mix(h0: var uint32, x: int64) =
    let u = uint32(cast[uint32](int32(x)))
    for shift in countup(0, 24, 8): h0 = (h0 xor ((u shr shift) and 255'u32)) * 16777619'u32
  while top <= bottom and left <= right:
    for c in left .. right: mix(h, v[2 + top * cols + c])
    inc top
    for r in top .. bottom: mix(h, v[2 + r * cols + right])
    if right == 0: break
    dec right
    if top <= bottom:
      for c in countdown(right, left): mix(h, v[2 + bottom * cols + c])
      if bottom == 0: break
      dec bottom
    if left <= right:
      for r in countdown(bottom, top): mix(h, v[2 + r * cols + left])
      inc left
  int64(h)
