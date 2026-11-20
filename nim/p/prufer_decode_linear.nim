## Uncompiled monotone-cursor Prüfer decoder draft.
proc pdlWrite(output: ptr UncheckedArray[uint8], offset: int, value: int) =
  let bits = uint64(value)
  for i in 0 ..< 8: output[offset+i] = uint8((bits shr (8*i)) and 255)

proc prufer_decode_linear*(input: ptr UncheckedArray[int64], length: csize_t,
                           output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "prufer_decode_linear".} =
  if input == nil or length < 1 or length > 4096: return -1
  let nv = input[0]
  if nv < 2 or nv > 4096 or length != csize_t(nv-1): return -1
  let n = int(nv)
  var count: array[4096, int]
  for i in 1 ..< int(length):
    if input[i] < 0 or input[i] >= nv: return -1
    inc count[int(input[i])]
  let needed = 16*(n-1)
  if output == nil or capacity < csize_t(needed): return -2
  var cursor = n-1
  while count[cursor] != 0: dec cursor
  var leaf = cursor
  for i in 1 ..< int(length):
    let v = int(input[i])
    pdlWrite(output, 16*(i-1), leaf)
    pdlWrite(output, 16*(i-1)+8, v)
    count[leaf] = -1
    dec count[v]
    if count[v] == 0 and v > cursor: leaf = v
    else:
      dec cursor
      while count[cursor] != 0: dec cursor
      leaf = cursor
  var other = 0
  while other == leaf or count[other] != 0: inc other
  pdlWrite(output, 16*(n-2), leaf)
  pdlWrite(output, 16*(n-2)+8, other)
  int64(needed)
