## Return the shortest common supersequence length of two packed ASCII sequences.
proc shortest_common_supersequence_length*(packed: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "shortest_common_supersequence_length".} =
  if packed.isNil or length < 2 or length > 512: return -1
  let leftLength = packed[0]
  let rightLength = packed[1]
  if leftLength < 0 or leftLength > 255 or rightLength < 0 or rightLength > 255: return -1
  if length != csize_t(2 + leftLength + rightLength): return -1
  for index in 0 ..< int(leftLength + rightLength):
    if packed[2 + index] < 0 or packed[2 + index] > 127: return -1

  let rows = int(leftLength) + 1
  let columns = int(rightLength) + 1
  var table: array[65536, int64]
  for i in 1 ..< rows:
    for j in 1 ..< columns:
      let cell = i * columns + j
      if packed[1 + i] == packed[1 + int(leftLength) + j]:
        table[cell] = table[(i - 1) * columns + j - 1] + 1
      else:
        let above = table[(i - 1) * columns + j]
        let left = table[i * columns + j - 1]
        table[cell] = max(above, left)
  leftLength + rightLength - table[(rows - 1) * columns + columns - 1]
