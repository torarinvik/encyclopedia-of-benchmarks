const
  MaxN = 16
  MaxK = 3
  MaxInput = 1557
  MaxRecords = 372
  Periods = 9
  BitWords = 39
  MaxOutput = 11912

type
  Record = object
    start, finish, period, errors: int
  PropagationState = object
    word: array[MaxN, int]
    starts, ends, copies: array[MaxN, int]
    records: array[MaxRecords, Record]
    known, generated: array[BitWords, uint64]
    n, budget, factorCount, recordCount: int

proc bitIndex(start, finish, period: int): int =
  (start * (MaxN + 1) + finish) * Periods + period

proc marked(bits: openArray[uint64], bit: int): bool =
  (bits[bit div 64] and (1'u64 shl (bit mod 64))) != 0

proc lce(s: var PropagationState, left, right: int): int =
  var length = 0
  while left + length < s.n and right + length < s.n and
        s.word[left + length] == s.word[right + length]:
    inc length
  length

proc lessRecord(a, b: Record): bool =
  if a.start != b.start: return a.start < b.start
  if a.finish != b.finish: return a.finish < b.finish
  if a.period != b.period: return a.period < b.period
  a.errors < b.errors

proc addRecord(s: var PropagationState, record: Record, isGenerated: bool) =
  let bit = bitIndex(record.start, record.finish, record.period)
  if marked(s.known, bit): return
  s.known[bit div 64] = s.known[bit div 64] or (1'u64 shl (bit mod 64))
  if isGenerated:
    s.generated[bit div 64] = s.generated[bit div 64] or (1'u64 shl (bit mod 64))
  var at = s.recordCount
  while at > 0 and lessRecord(record, s.records[at - 1]):
    s.records[at] = s.records[at - 1]
    dec at
  s.records[at] = record
  inc s.recordCount

proc factorsValid(s: var PropagationState): bool =
  if s.factorCount <= 0 or s.factorCount > s.n: return false
  var position = 0
  for f in 0 ..< s.factorCount:
    let a = s.starts[f]
    let b = s.ends[f]
    let c = s.copies[f]
    if a != position or a < 0 or b <= a or b > s.n: return false
    if f == 0:
      if a != 0 or b != 1 or c != -1: return false
      position = b
      continue
    var longest = 0
    for earlier in 0 ..< a: longest = max(longest, lce(s, earlier, a))
    if b != min(s.n, a + longest + 1): return false
    let prefix = b - a - 1
    if prefix == 0:
      if c != -1: return false
    elif c < 0 or c >= a or lce(s, c, a) != prefix:
      return false
    position = b
  position == s.n

proc mismatchCount(s: var PropagationState, start, finish, period: int): int =
  var errors = 0
  for i in start ..< finish - period:
    if s.word[i] != s.word[i + period]: inc errors
  errors

proc seedValid(s: var PropagationState, r: Record): bool =
  let a = r.start
  let b = r.finish
  let p = r.period
  if a < 0 or a >= b or b > s.n or p < 1 or p > s.n div 2 or b - a < 2 * p: return false
  let errors = mismatchCount(s, a, b, p)
  if errors != r.errors or errors > s.budget: return false
  if a > 0 and errors + int(s.word[a - 1] != s.word[a + p - 1]) <= s.budget: return false
  if b < s.n and errors + int(s.word[b - p] != s.word[b]) <= s.budget: return false
  true

proc propagate(s: var PropagationState) =
  for f in 0 ..< s.factorCount:
    let a = s.starts[f]
    let b = s.ends[f]
    let c = s.copies[f]
    let copied = b - a - 1
    if copied <= 0: continue
    let delta = a - c
    let copyEnd = c + copied
    for target in (a + 1) ..< (b - 1):
      let sourceStart = target - delta
      var index = 0
      while index < s.recordCount and s.records[index].start < sourceStart: inc index
      while index < s.recordCount and s.records[index].start == sourceStart:
        let source = s.records[index]
        if source.finish > copyEnd: break
        let targetEnd = source.finish + delta
        if targetEnd <= b - 2:
          s.addRecord(Record(start: target, finish: targetEnd, period: source.period, errors: source.errors), true)
        inc index

proc putI64(output: ptr UncheckedArray[uint8], offset: int, value: uint64) =
  for byte in 0 ..< 8: output[offset + byte] = uint8((value shr (8 * byte)) and 255'u64)

proc k_repetition_within_factor_copy_propagation*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "k_repetition_within_factor_copy_propagation".} =
  if input.isNil or length < 2 or length > csize_t(MaxInput): return -1
  if input[0] < 1 or input[0] > MaxN or input[1] < 0 or input[1] > MaxK: return -1
  let n = int(input[0])
  let budget = int(input[1])
  if length < csize_t(n + 3): return -1
  var s: PropagationState
  s.n = n
  s.budget = budget
  var cursor = 2
  for i in 0 ..< n:
    if input[cursor] < 0 or input[cursor] > 5: return -1
    s.word[i] = int(input[cursor])
    inc cursor
  for i in 0 ..< n - 1:
    if s.word[i] == s.word[n - 1]: return -1
  if cursor >= int(length) or input[cursor] < 1 or input[cursor] > n: return -1
  s.factorCount = int(input[cursor])
  inc cursor
  if cursor + 3 * s.factorCount >= int(length): return -1
  for i in 0 ..< s.factorCount:
    let a = input[cursor]
    let b = input[cursor + 1]
    let c = input[cursor + 2]
    if a < 0 or a > n or b < 0 or b > n or c < -1 or c > n: return -1
    s.starts[i] = int(a)
    s.ends[i] = int(b)
    s.copies[i] = int(c)
    cursor += 3
  if cursor >= int(length) or not factorsValid(s): return -1
  let seedCountValue = input[cursor]
  inc cursor
  if seedCountValue < 0 or seedCountValue > MaxRecords or cursor + 4 * int(seedCountValue) != int(length): return -1
  for _ in 0 ..< int(seedCountValue):
    let a = input[cursor]
    let b = input[cursor + 1]
    let p = input[cursor + 2]
    let e = input[cursor + 3]
    if a < 0 or a > n or b < 0 or b > n or p < 0 or p > n or e < 0 or e > MaxK: return -1
    let seed = Record(start: int(a), finish: int(b), period: int(p), errors: int(e))
    if not seedValid(s, seed): return -1
    s.addRecord(seed, false)
    cursor += 4
  s.propagate()
  var count = 0
  for i in 0 ..< s.recordCount:
    let r = s.records[i]
    if marked(s.generated, bitIndex(r.start, r.finish, r.period)): inc count
  let written = 8 + count * 32
  if written > MaxOutput: return -1
  if output.isNil or capacity < csize_t(written): return -2
  putI64(output, 0, uint64(count))
  var offset = 8
  for i in 0 ..< s.recordCount:
    let r = s.records[i]
    if not marked(s.generated, bitIndex(r.start, r.finish, r.period)): continue
    putI64(output, offset, uint64(r.start)); offset += 8
    putI64(output, offset, uint64(r.finish)); offset += 8
    putI64(output, offset, uint64(r.period)); offset += 8
    putI64(output, offset, uint64(r.errors)); offset += 8
  int64(written)
