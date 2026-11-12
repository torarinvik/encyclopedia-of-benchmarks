## Return the LCS length with a descending-position Hunt-Szymanski scan.
proc hunt_szymanski_lcs*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "hunt_szymanski_lcs".} =
  if input.isNil or length < 2 or length > 131: return -1
  let nValue = input[0]
  let mValue = input[1]
  if nValue < 0 or nValue > 64 or mValue < 0 or mValue > 64: return -1
  if length != csize_t(2 + nValue + mValue): return -1
  let n = int(nValue)
  let m = int(mValue)
  for i in 0 ..< n + m:
    if input[2 + i] < 0 or input[2 + i] > 127: return -1

  var rightPositions: array[8192, int32]
  var positionCount: array[128, int32]
  var tails: array[64, int32]
  for symbol in 0 ..< 128:
    positionCount[symbol] = 0
  for j in 0 ..< m:
    let symbol = int(input[2 + n + j])
    let count = int(positionCount[symbol])
    rightPositions[symbol * 64 + count] = int32(j)
    positionCount[symbol] = int32(count + 1)

  var tailCount = 0
  for i in 0 ..< n:
    let symbol = int(input[2 + i])
    var count = int(positionCount[symbol])
    while count > 0:
      dec count
      let position = rightPositions[symbol * 64 + count]
      var low = 0
      var high = tailCount
      while low < high:
        let middle = low + (high - low) div 2
        if tails[middle] >= position: high = middle
        else: low = middle + 1
      if low == tailCount:
        tails[tailCount] = position
        inc tailCount
      else:
        tails[low] = position
  int64(tailCount)
