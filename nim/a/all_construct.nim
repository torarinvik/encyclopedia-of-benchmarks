const MaxTarget = 6
const MaxWords = 4
const MaxWays = 4096

proc all_construct*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "all_construct".} =
  if input.isNil or length < 2 or input[0] < 0 or input[0] > MaxTarget: return -1
  let n = int(input[0])
  for i in 0 ..< n:
    if input[i + 1] < 97 or input[i + 1] > 122: return -1
  let wcSlot = n + 1
  if csize_t(wcSlot) >= length or input[wcSlot] < 0 or input[wcSlot] > MaxWords: return -1
  let words = int(input[wcSlot])
  var starts: array[MaxWords, int]
  var wordLengths: array[MaxWords, int]
  var cursor = wcSlot + 1
  for w in 0 ..< words:
    if csize_t(cursor) >= length or input[cursor] < 1 or input[cursor] > MaxTarget: return -1
    let wl = int(input[cursor]); inc cursor
    if csize_t(cursor + wl) > length: return -1
    starts[w] = cursor; wordLengths[w] = wl
    for j in 0 ..< wl:
      if input[cursor + j] < 97 or input[cursor + j] > 122: return -1
    cursor += wl
  if csize_t(cursor) != length: return -1
  var paths: array[(MaxTarget + 1) * MaxWays * MaxTarget, uint8]
  var pathLengths: array[(MaxTarget + 1) * MaxWays, uint8]
  var counts: array[MaxTarget + 1, int]
  counts[0] = 1
  for pos in 0 ..< n:
    for w in 0 ..< words:
      let wl = wordLengths[w]
      if wl > n - pos: continue
      var matched = true
      for j in 0 ..< wl:
        if input[pos + 1 + j] != input[starts[w] + j]: matched = false
      if not matched: continue
      let ending = pos + wl
      for row in 0 ..< counts[pos]:
        let dest = counts[ending]
        if dest >= MaxWays: return -1
        inc counts[ending]
        let srcBase = (pos * MaxWays + row) * MaxTarget
        let dstBase = (ending * MaxWays + dest) * MaxTarget
        let plen = int(pathLengths[pos * MaxWays + row])
        for k in 0 ..< plen: paths[dstBase + k] = paths[srcBase + k]
        paths[dstBase + plen] = uint8(w)
        pathLengths[ending * MaxWays + dest] = uint8(plen + 1)
  var required = 0
  for row in 0 ..< counts[n]:
    let plen = int(pathLengths[n * MaxWays + row]); inc required
    for k in 0 ..< plen: required += 1 + wordLengths[int(paths[(n * MaxWays + row) * MaxTarget + k])]
  if csize_t(required) > outputCapacity or (required > 0 and output.isNil): return -2
  if counts[n] == 0: return 0
  var written = 0
  for row in 0 ..< counts[n]:
    let pathBase = (n * MaxWays + row) * MaxTarget
    let plen = int(pathLengths[n * MaxWays + row])
    output[written] = uint8(plen); inc written
    for k in 0 ..< plen:
      let w = int(paths[pathBase + k]); let wl = wordLengths[w]
      output[written] = uint8(wl); inc written
      for j in 0 ..< wl: output[written] = uint8(input[starts[w] + j]); inc written
  int64(counts[n])
