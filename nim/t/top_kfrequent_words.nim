proc sift(heap: var array[64, int], counts: array[64, int], size, root: int) =
  var best = root
  let left = root * 2 + 1
  let right = left + 1
  if left < size and counts[heap[left]] > counts[heap[best]]: best = left
  if right < size and counts[heap[right]] > counts[heap[best]]: best = right
  if best != root:
    swap(heap[root], heap[best])
    sift(heap, counts, size, best)

proc top_kfrequent_words*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "top_kfrequent_words".} =
  if values == nil or length < 2 or length > 1090 or values[0] < 0 or values[0] > 64 or values[1] < 0 or values[1] > 64: return -1
  let k = int(values[0]); let wordCount = int(values[1]); var pos = 2; var distinct = 0
  var words: array[64, array[16, uint8]]; var lens: array[64, int]; var counts: array[64, int]
  for _ in 0 ..< wordCount:
    if pos >= int(length) or values[pos] < 1 or values[pos] > 16: return -1
    let wordLen = int(values[pos]); inc pos
    if wordLen > int(length) - pos: return -1
    for j in 0 ..< wordLen:
      if values[pos+j] < 97 or values[pos+j] > 122: return -1
    var id = 0
    while id < distinct:
      if lens[id] == wordLen:
        var j = 0
        while j < wordLen and int64(words[id][j]) == values[pos+j]: inc j
        if j == wordLen: break
      inc id
    if id == distinct:
      lens[id] = wordLen
      for j in 0 ..< wordLen: words[id][j] = uint8(values[pos+j])
      inc distinct
    inc counts[id]; pos += wordLen
  if pos != int(length): return -1
  for id in 0 ..< distinct:
    var rank = 0
    for other in 0 ..< distinct:
      let common = min(lens[id], lens[other])
      var j = 0
      while j < common and words[other][j] == words[id][j]: inc j
      if (j < common and words[other][j] < words[id][j]) or (j == common and lens[other] < lens[id]): inc rank
    counts[id] = counts[id] * 65 + distinct - rank
  var heap: array[64, int]
  for i in 0 ..< distinct: heap[i] = i
  var build = distinct div 2
  while build > 0:
    dec build
    sift(heap, counts, distinct, build)
  let limit = min(k, distinct)
  var temp: array[1089, uint8]; var at = 0
  for _ in 0 ..< limit:
    let id = heap[0]
    for j in 0 ..< lens[id]: temp[at+j] = words[id][j]
    at += lens[id]; temp[at] = 10; inc at
    dec distinct; heap[0] = heap[distinct]
    if distinct > 0: sift(heap, counts, distinct, 0)
  temp[at] = 0; inc at
  if output == nil or int(outputCapacity) < at: return -2
  for i in 0 ..< at: output[i] = temp[i]
  int64(at)
