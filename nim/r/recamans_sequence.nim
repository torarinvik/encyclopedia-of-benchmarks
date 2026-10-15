proc recamans_sequence*(index: int64): int64 {.cdecl, exportc: "recamans_sequence".} =
  if index < 0 or index > 32: return -1
  var seen: array[529, bool]
  seen[0] = true
  var previous = 0'i64
  var step = 1'i64
  while step <= index:
    var candidate = previous - step
    if candidate < 0 or seen[int(candidate)]:
      candidate = previous + step
    seen[int(candidate)] = true
    previous = candidate
    step += 1
  return previous
