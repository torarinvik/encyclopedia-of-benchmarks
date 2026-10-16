proc pattern_matching*(v: ptr UncheckedArray[int64], n: csize_t): int64 {.cdecl, exportc: "pattern_matching".} =
  if v.isNil or n < 3 or n > 130 or v[0] < 0 or v[0] > 64: return -1
  let textLen=int(v[0]);let pp=textLen+1
  if int(n)<pp+1 or v[pp]<1 or v[pp]>64:return -1
  let patLen=int(v[pp]);if int(n)!=pp+patLen+1 or patLen>textLen:return -1
  for i in 1..<pp:
    if v[i]<0 or v[i]>127:return -1
  for i in pp+1..<int(n):
    if v[i]<0 or v[i]>127:return -1
  for i in 0..textLen-patLen:
    var j=0
    while j<patLen and v[i+j+1]==v[pp+j+1]:inc j
    if j==patLen:return int64(i)
  -1

