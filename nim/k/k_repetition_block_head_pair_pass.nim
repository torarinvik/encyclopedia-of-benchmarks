const
  MaxN = 24
  MaxK = 3
  MaxInput = 27
  MaxContext = 48
  MaxFactors = 25
  MaxPeriods = 13
  BitWords = 117
  MaxOutput = 39112

type PassState = object
  text: array[MaxN, int]
  starts, ends: array[MaxFactors, int]
  factorCount, n, budget: int
  seen: array[BitWords, uint64]

proc extendRight(w: array[MaxContext, int], size, center, period, allowed: int): int =
  let left = center - period
  let limit = min(size - left, size - center)
  var errors = 0
  for j in 0..<limit:
    if w[left + j] != w[center + j]:
      inc errors
      if errors > allowed: return j
  limit

proc extendLeft(w: array[MaxContext, int], center, period, allowed: int): int =
  let limit = center - period
  var errors = 0
  for j in 0..<limit:
    if w[center - period - 1 - j] != w[center - 1 - j]:
      inc errors
      if errors > allowed: return j
  limit

proc mark(s: var PassState, base, size, center, nextHead, lo, hi, period: int) =
  if hi >= size or hi - lo + 1 < 2 * period: return
  if lo > center + 1 or hi + 1 < center: return
  if lo <= nextHead + 1 and hi + 1 >= nextHead: return
  let start = base + lo
  let finish = base + hi
  if finish >= s.n: return
  let index = (start * MaxN + finish) * MaxPeriods + period
  s.seen[index div 64] = s.seen[index div 64] or (1'u64 shl (index mod 64))

proc atHead(s: var PassState, w: array[MaxContext, int], size, base, center, nextHead: int) =
  if center <= 0 or center + 1 >= size: return
  for period in 1..center:
    for split in 0..s.budget:
      let f = extendRight(w, size, center, period, split)
      let b = extendLeft(w, center, period, s.budget - split)
      if f <= period and f + b >= period:
        s.mark(base, size, center, nextHead, center - period - b, center + f - 1, period)
  var reversed: array[MaxContext, int]
  for i in 0..<size: reversed[i] = w[size - 1 - i]
  let rc = size - 1 - center
  for period in 1..rc:
    for split in 0..s.budget:
      let f = extendRight(reversed, size, rc, period, split)
      let b = extendLeft(reversed, rc, period, s.budget - split)
      if f <= period and f + b >= period:
        let rs = rc - period - b
        let re = rc + f - 1
        s.mark(base, size, center, nextHead, size - 1 - re, size - 1 - rs, period)

proc factorize(s: var PassState) =
  var pos = 0
  while pos < s.n:
    var best = 0
    for earlier in 0..<pos:
      var matched = 0
      while pos + matched < s.n and earlier + matched < s.n and
            s.text[earlier + matched] == s.text[pos + matched]:
        inc matched
      best = max(best, matched)
    let finish = min(s.n, pos + best + 1)
    s.starts[s.factorCount] = pos
    s.ends[s.factorCount] = finish
    inc s.factorCount
    pos = finish

proc runHeads(s: var PassState) =
  let block = s.budget + 2
  let blockCount = (s.factorCount + block - 1) div block
  for bi in 0..<max(0, blockCount - 1):
    let first = bi * block
    let firstEnd = min(s.factorCount, first + block)
    let secondEnd = min(s.factorCount, firstEnd + block)
    let head = s.ends[firstEnd - 1] - 1
    let nextHead = s.ends[secondEnd - 1] - 1
    let pairStart = s.starts[first]
    let pairEnd = s.ends[secondEnd - 1]
    let span = pairEnd - pairStart
    let base = max(0, pairStart - span)
    let size = pairEnd - base
    var local: array[MaxContext, int]
    for i in 0..<size: local[i] = s.text[base + i]
    s.atHead(local, size, base, head - base, nextHead - base)

proc marked(s: var PassState, start, finish, period: int): bool =
  let index = (start * MaxN + finish) * MaxPeriods + period
  (s.seen[index div 64] and (1'u64 shl (index mod 64))) != 0

proc putI64(output: ptr UncheckedArray[uint8], offset: int, value: uint64) =
  for b in 0..<8: output[offset + b] = uint8((value shr (8 * b)) and 255'u64)

proc k_repetition_block_head_pair_pass*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "k_repetition_block_head_pair_pass".} =
  if input.isNil or length < 3 or length > csize_t(MaxInput): return -1
  let nv = input[0]
  let kv = input[1]
  if nv < 1 or nv > MaxN or kv < 0 or kv > MaxK: return -1
  let n = int(nv)
  let budget = int(kv)
  if int(length) != n + 2: return -1
  var state: PassState
  state.n = n
  state.budget = budget
  for i in 0..<n:
    if input[i + 2] < 0 or input[i + 2] > 4: return -1
    state.text[i] = int(input[i + 2])
  for i in 0..<n-1:
    if state.text[i] == state.text[n - 1]: return -1
  state.factorize()
  state.runHeads()
  var count = 0
  for start in 0..<n:
    for lengthValue in 2..(n - start):
      let finish = start + lengthValue - 1
      for period in 1..(lengthValue div 2):
        if state.marked(start, finish, period): inc count
  let written = 8 + count * 32
  if written > MaxOutput: return -1
  if output.isNil or capacity < csize_t(written): return -2
  putI64(output, 0, uint64(count))
  var offset = 8
  for start in 0..<n:
    for lengthValue in 2..(n - start):
      let finish = start + lengthValue - 1
      for period in 1..(lengthValue div 2):
        if not state.marked(start, finish, period): continue
        var errors = 0
        for i in start..(finish - period):
          if state.text[i] != state.text[i + period]: inc errors
        putI64(output, offset, uint64(start)); offset += 8
        putI64(output, offset, uint64(lengthValue)); offset += 8
        putI64(output, offset, uint64(period)); offset += 8
        putI64(output, offset, uint64(errors)); offset += 8
  int64(written)
