proc put32(o: ptr UncheckedArray[uint8], x: uint32) =
  for k in 0..<4: o[k] = uint8((x shr (8*k)) and 255)
proc putF64(o: ptr UncheckedArray[uint8], x: float64) =
  let b = cast[uint64](x)
  for k in 0..<8: o[4+k] = uint8((b shr (8*k)) and 255)
proc evaluate_expression*(v: ptr UncheckedArray[int64], n: csize_t, o: ptr UncheckedArray[uint8], cap: csize_t): int64 {.cdecl, exportc:"evaluate_expression".} =
  if v == nil or n < 3 or n > 131: return -1
  let count = v[0]
  if count < 1 or count > 64 or n != csize_t(1+2*count): return -1
  var stack: array[64,float64]
  var depth = 0
  var valid = true
  for i in 0..<int(count):
    let op = v[1+2*i]
    let x = v[2+2*i]
    if op == 0:
      if x < -1_000_000_000 or x > 1_000_000_000: return -1
      stack[depth] = float64(x)/1000.0
      inc depth
    elif op >= 1 and op <= 4:
      if x != 0: return -1
      if depth < 2: valid = false; break
      dec depth
      let right = stack[depth]
      dec depth
      let left = stack[depth]
      if op == 1: stack[depth] = left+right
      elif op == 2: stack[depth] = left-right
      elif op == 3: stack[depth] = left*right
      elif right == 0.0: valid = false; break
      else: stack[depth] = left/right
      inc depth
    else:
      valid = false
      break
  valid = valid and depth == 1
  let needed = if valid: 12 else: 4
  if o == nil or cap < csize_t(needed): return -2
  put32(o, uint32(if valid: 1 else: 0))
  if valid: putF64(o, stack[0])
  int64(needed)
