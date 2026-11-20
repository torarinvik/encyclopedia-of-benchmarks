## Uncompiled duplicate-aware distinct-LCS counting draft.
proc count_distinct_lcs*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "count_distinct_lcs".} =
  if input == nil or length < 2 or length > 131: return -1
  let nr = input[0]
  let mr = input[1]
  if nr < 0 or nr > 64 or mr < 0 or mr > 64 or length != csize_t(2+nr+mr): return -1
  let n = int(nr)
  let m = int(mr)
  for i in 2 ..< int(length):
    if input[i] < 0 or input[i] > 255: return -1
  var prevLen, currLen: array[65, int]
  var prevCount, currCount: array[65, int64]
  for j in 0 .. m: prevCount[j] = 1
  for i in 1 .. n:
    currLen[0] = 0
    currCount[0] = 1
    for j in 1 .. m:
      if input[1+i] == input[1+n+j]:
        currLen[j] = prevLen[j-1]+1
        currCount[j] = prevCount[j-1]
      else:
        let best = max(prevLen[j], currLen[j-1])
        var count = 0'i64
        if prevLen[j] == best: count += prevCount[j]
        if currLen[j-1] == best: count += currCount[j-1]
        if prevLen[j-1] == best: count -= prevCount[j-1]
        currLen[j] = best
        currCount[j] = (count+1_000_000_007) mod 1_000_000_007
    for j in 0 .. m:
      prevLen[j] = currLen[j]
      prevCount[j] = currCount[j]
  prevCount[m]
