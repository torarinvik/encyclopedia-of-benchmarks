proc palindrome_with_stack*(v: ptr UncheckedArray[int64], n: csize_t): int64 {.cdecl, exportc: "palindrome_with_stack".} =
  if v.isNil or n < 1 or n > 129 or v[0] < 0 or v[0] > 128 or n != csize_t(v[0] + 1): return -1
  let length = int(v[0]); var stack: array[128, byte]
  for i in 0..<length:
    let x = v[i + 1]; if x < 0 or x > 127: return -1
    var c = byte(x); if c >= byte('A') and c <= byte('Z'): c += 32
    stack[i] = c
  for i in 0..<length:
    if stack[i] != stack[length - 1 - i]: return 0
  1

