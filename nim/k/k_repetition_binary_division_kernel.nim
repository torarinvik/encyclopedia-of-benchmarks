const
  MaxN = 32
  MaxK = 3
  MaxInput = 35
  MaxPeriods = 17
  BitWords = 272
  MaxFactors = 33
  MaxOutput = 91400

type Search = object
  text: array[MaxN, int]
  n, budget, factorCount: int
  starts, ends: array[MaxFactors, int]
  seen: array[BitWords, uint64]

proc lp(text: array[MaxN, int], lo, hi, center, period, allowed: int): int =
  let left = center - period
  let limit = min(hi - left, hi - center)
  var errors = 0
  for j in 0..<limit:
    if text[left + j] != text[center + j]:
      inc errors
      if errors > allowed: return j
  limit

proc ls(text: array[MaxN, int], lo, center, period, allowed: int): int =
  let limit = min(center - period - lo, center - lo)
  var errors = 0
  for j in 0..<limit:
    if text[center - period - 1 - j] != text[center - 1 - j]:
      inc errors
      if errors > allowed: return j
  limit

proc mark(state: var Search, lo, lastHead, localStart, localEnd, period: int) =
  let start = lo + localStart
  let finish = lo + localEnd
  if start <= lo or finish >= state.n or finish - start + 1 < 2 * period: return
  if start <= lastHead + 1 and finish + 1 >= lastHead: return
  let index = (start * MaxN + finish) * MaxPeriods + period
  state.seen[index div 64] = state.seen[index div 64] or (1'u64 shl (index mod 64))

proc atCenter(state: var Search, lo, hi, center, lastHead: int) =
  if center <= lo or center + 1 >= hi: return
  for period in 1..(center - lo):
    for k in 0..state.budget:
      let forward = lp(state.text, lo, hi, center, period, k)
      let backward = ls(state.text, lo, center, period, state.budget - k)
      if forward <= period and forward + backward >= period:
        state.mark(lo, lastHead, center - period - backward - lo,
                   center + forward - 1 - lo, period)
  var reversed: array[MaxN, int]
  let size = hi - lo
  for i in 0..<size: reversed[i] = state.text[hi - 1 - i]
  let rc = size - 1 - (center - lo)
  for period in 1..rc:
    for k in 0..state.budget:
      let forward = lp(reversed, 0, size, rc, period, k)
      let backward = ls(reversed, 0, rc, period, state.budget - k)
      if forward <= period and forward + backward >= period:
        let reverseStart = rc - period - backward
        let reverseEnd = rc + forward - 1
        state.mark(lo, lastHead, size - 1 - reverseEnd, size - 1 - reverseStart, period)

proc divide(state: var Search, first, last: int) =
  if first >= last: return
  let middle = first + (last - first) div 2
  let lo = state.starts[first]
  let hi = state.ends[last]
  let center = state.ends[middle] - 1
  let lastHead = state.ends[last] - 1
  state.atCenter(lo, hi, center, lastHead)
  state.divide(first, middle)
  state.divide(middle + 1, last)

proc encodeI64(output: ptr UncheckedArray[uint8], offset: int, value: uint64) =
  for byte in 0..<8: output[offset + byte] = uint8((value shr (8 * byte)) and 255'u64)

proc k_repetition_binary_division_kernel*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "k_repetition_binary_division_kernel".} =
  if input.isNil or length < 3 or length > csize_t(MaxInput): return -1
  let nValue = input[0]
  let budgetValue = input[1]
  if nValue < 1 or nValue > MaxN or budgetValue < 0 or budgetValue > MaxK: return -1
  let n = int(nValue)
  let budget = int(budgetValue)
  if int(length) != n + 2: return -1
  var state: Search
  state.n = n
  state.budget = budget
  for i in 0..<n:
    if input[i + 2] < 0 or input[i + 2] > 4: return -1
    state.text[i] = int(input[i + 2])
  for i in 0..<n-1:
    if state.text[i] == state.text[n - 1]: return -1

  var pos = 0
  while pos < n:
    var best = 0
    for earlier in 0..<pos:
      var matched = 0
      while pos + matched < n and earlier + matched < n
          and state.text[earlier + matched] == state.text[pos + matched]: inc matched
      best = max(best, matched)
    let finish = min(n, pos + best + 1)
    state.starts[state.factorCount] = pos
    state.ends[state.factorCount] = finish
    inc state.factorCount
    pos = finish
  let block = budget + 2
  var first = 0
  while first < state.factorCount:
    state.divide(first, min(state.factorCount, first + block) - 1)
    first += block

  var records = 0
  for start in 0..<n:
    for len in 2..(n - start):
      let finish = start + len - 1
      for period in 1..(len div 2):
        let index = (start * MaxN + finish) * MaxPeriods + period
        if (state.seen[index div 64] and (1'u64 shl (index mod 64))) != 0: inc records
  let written = 8 + records * 32
  if written > MaxOutput: return -1
  if output.isNil or capacity < csize_t(written): return -2
  encodeI64(output, 0, uint64(records))
  var offset = 8
  for start in 0..<n:
    for len in 2..(n - start):
      let finish = start + len - 1
      for period in 1..(len div 2):
        let index = (start * MaxN + finish) * MaxPeriods + period
        if (state.seen[index div 64] and (1'u64 shl (index mod 64))) == 0: continue
        var mismatches = 0
        for i in start..(finish - period):
          if state.text[i] != state.text[i + period]: inc mismatches
        encodeI64(output, offset, uint64(start)); offset += 8
        encodeI64(output, offset, uint64(len)); offset += 8
        encodeI64(output, offset, uint64(period)); offset += 8
        encodeI64(output, offset, uint64(mismatches)); offset += 8
  int64(written)
