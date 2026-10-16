proc palindrome_singly_linked_list*(v: ptr UncheckedArray[int64], n: csize_t): int64 {.cdecl, exportc: "palindrome_singly_linked_list".} =
  if v.isNil or n < 1 or n > 65 or v[0] < 0 or v[0] > 64 or n != csize_t(v[0]+1): return -1
  let length=int(v[0])
  for i in 1..<int(n):
    if v[i] < -2_147_483_648'i64 or v[i] > 2_147_483_647'i64: return -1
  var slow=0; var fast=0
  while fast+1 < length: inc slow; fast += 2
  let suffix=length-slow
  for i in 0..<suffix:
    if v[i+1] != v[length-i]: return 0
  1

