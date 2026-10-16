proc put64(output: ptr UncheckedArray[uint8], pos: var int, value: int64) =
  for i in 0..<8: output[pos + i] = uint8((cast[uint64](value) shr (i * 8)) and 255)
  pos += 8
proc powerset*(v: ptr UncheckedArray[int64], n: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "powerset".} =
  if v.isNil or n < 1 or n > 7 or v[0] < 0 or v[0] > 6 or n != csize_t(v[0] + 1): return -1
  let count = int(v[0]); let subsets = 1 shl count; let needed = 2 + subsets + 8 * count * (subsets div 2)
  for i in 1..<int(n): if v[i] < -1_000_000 or v[i] > 1_000_000: return -1
  if output.isNil or int(capacity) < needed: return -2
  output[0] = uint8(subsets); output[1] = uint8(subsets shr 8)
  var selected: array[6, int64]; var cursor = 2
  proc emit(at, used: int) =
    if at == count:
      output[cursor] = uint8(used); inc cursor
      for j in 0..<used: put64(output, cursor, selected[j])
      return
    emit(at + 1, used)
    selected[used] = v[at + 1]
    emit(at + 1, used + 1)
  emit(0, 0)
  int64(needed)
