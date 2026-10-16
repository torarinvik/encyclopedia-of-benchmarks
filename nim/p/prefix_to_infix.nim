proc get16(p: ptr UncheckedArray[uint8], i: int): int = int(p[i]) or (int(p[i + 1]) shl 8)
proc put16(p: ptr UncheckedArray[uint8], i, x: int) = p[i] = uint8(x); p[i + 1] = uint8(x shr 8)
proc letter(x: int64): bool = (x >= 65 and x <= 90) or (x >= 97 and x <= 122)
proc operator(x: int64): bool = x == 43 or x == 45 or x == 42 or x == 47 or x == 94
proc prefix_to_infix*(v: ptr UncheckedArray[int64], n: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "prefix_to_infix".} =
  if v.isNil or n < 1 or n > 64 or v[0] < 0 or v[0] > 63 or n != csize_t(v[0] + 1): return -1
  if output.isNil or capacity < 8192: return -2
  let count = int(v[0]); if count == 0: return 0
  if count == 1:
    if not letter(v[1]): return -1
    output[0] = uint8(v[1]); return 1
  var stack = 0; var scratch = 256
  for i in countdown(count, 1):
    let x = v[i]
    if operator(x):
      if stack < 2: return -1
      let l = stack - 2; let r = stack - 1
      let ls = get16(output, l * 4); let ll = get16(output, l * 4 + 2)
      let rs = get16(output, r * 4); let rl = get16(output, r * 4 + 2)
      let start = scratch; output[scratch] = uint8(ord('(')); inc scratch
      for j in 0..<rl: output[scratch] = output[rs + j]; inc scratch
      output[scratch] = uint8(x); inc scratch
      for j in 0..<ll: output[scratch] = output[ls + j]; inc scratch
      output[scratch] = uint8(ord(')')); inc scratch
      put16(output, l * 4, start); put16(output, l * 4 + 2, scratch - start); dec stack
    else:
      if not letter(x): return -1
      put16(output, stack * 4, scratch); put16(output, stack * 4 + 2, 1)
      output[scratch] = uint8(x); inc scratch; inc stack
    if scratch > int(capacity): return -2
  if stack != 1: return -1
  let start = get16(output, 0); let size = get16(output, 2)
  for i in 0..<size: output[i] = output[start + i]
  int64(size)
