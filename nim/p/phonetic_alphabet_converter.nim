const Words: array[36, string] = ["Alpha", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot", "Golf", "Hotel", "India", "Juliett", "Kilo", "Lima", "Mike", "November", "Oscar", "Papa", "Quebec", "Romeo", "Sierra", "Tango", "Uniform", "Victor", "Whiskey", "X-ray", "Yankee", "Zulu", "Zero", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine"]
proc phonetic_alphabet_converter*(v: ptr int64, n: uint64, out: ptr uint8, cap: uint64): int64 {.cdecl, exportc: "phonetic_alphabet_converter".} =
  if v == nil or n < 1 or n > 65 or v[0] < 0 or v[0] > 64 or n != uint64(v[0] + 1): return -1
  if out == nil or cap < 576: return -2
  var at = 0'u64
  var emitted = false
  for i in 0'u64 ..< uint64(v[0]):
    let raw = v[i + 1]
    if not (raw in [9'i64, 10, 11, 12, 13, 32] or raw in 33'i64 .. 126): return -1
    if raw in [9'i64, 10, 11, 12, 13, 32]: continue
    var c = int(raw)
    if c in ord('a') .. ord('z'): c -= 32
    if emitted: out[at] = 32; inc at
    emitted = true
    if c in ord('A') .. ord('Z') or c in ord('0') .. ord('9'):
      let word = if c >= ord('A') and c <= ord('Z'): Words[c - ord('A')] else: Words[26 + c - ord('0')]
      for ch in word: out[at] = uint8(ord(ch)); inc at
    else:
      out[at] = uint8(c); inc at
  int64(at)
