proc scan(s: ptr UncheckedArray[byte], lo, hi: int, h: var uint64) =
  var depth = 0; var begin = 0
  for i in lo..<hi:
    if s[i] == byte('<'):
      if depth == 0: begin = i
      inc depth
    elif s[i] == byte('>'):
      dec depth
      if depth == 0:
        for j in begin..i: h = (h * 257 + uint64(s[j]) + 1) mod 1_000_000_007
        scan(s, begin + 1, i, h)
proc parse_nested_brackets*(v: ptr UncheckedArray[int64], n: csize_t): int64 {.cdecl, exportc: "parse_nested_brackets".} =
  if v.isNil or n < 1 or n > 129 or v[0] < 0 or v[0] > 128 or n != csize_t(v[0] + 1): return -1
  let length = int(v[0]); var s: array[128, byte]; var depth = 0
  for i in 0..<length:
    if v[i+1] < 0 or v[i+1] > 127: return -1
    s[i] = byte(v[i+1])
    if s[i] == byte('<'): inc depth
    elif s[i] == byte('>'):
      dec depth
      if depth < 0: return -1
  if depth != 0: return -1
  var h = 0'u64; scan(cast[ptr UncheckedArray[byte]](addr s[0]),0,length,h); int64(h)

