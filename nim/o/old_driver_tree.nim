const
  MaxN = 32
  MaxQ = 32
  MaxInput = 195
  MaxRuns = 36
type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]
  Run = object
    left, right, value: int64
  Operation = object
    kind, left, right, arg, extra: int64

proc lowerBound(runs: array[MaxRuns, Run], count: int, point: int64): int =
  var lo = 0
  var hi = count
  while lo < hi:
    let mid = lo + (hi - lo) div 2
    if runs[mid].left < point: lo = mid + 1 else: hi = mid
  lo

proc splitAt(runs: var array[MaxRuns, Run], count: var int, point, n: int64) =
  if point <= 0 or point >= n: return
  let at = lowerBound(runs, count, point)
  if at < count and runs[at].left == point: return
  let old = runs[at - 1]
  var i = count
  while i > at:
    runs[i] = runs[i - 1]
    dec i
  runs[at - 1].right = point - 1
  runs[at] = Run(left: point, right: old.right, value: old.value)
  inc count

proc coalesce(runs: var array[MaxRuns, Run], count: var int) =
  var write = 0
  for read in 0 ..< count:
    if write > 0 and runs[write - 1].right + 1 == runs[read].left and runs[write - 1].value == runs[read].value:
      runs[write - 1].right = runs[read].right
    else:
      runs[write] = runs[read]
      inc write
  count = write

proc modularPower(base, exponent, modulus: int64): int64 =
  var value = base mod modulus
  if value < 0: value += modulus
  var power = exponent
  result = 1 mod modulus
  while power > 0:
    if (power and 1) != 0: result = result * value mod modulus
    value = value * value mod modulus
    power = power shr 1

proc storeLe(output: U8Output, offset: int, value: int64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8(bits and 255)
    bits = bits shr 8

proc old_driver_tree*(input: I64Input, length: csize_t, output: U8Output,
    capacity: csize_t): int64 {.cdecl, exportc: "old_driver_tree".} =
  if input == nil or length < 2 or length > MaxInput: return -1
  let nv = input[0]
  let qv = input[1]
  if nv < 1 or nv > MaxN or qv < 0 or qv > MaxQ or length < csize_t(2 + nv): return -1
  let n = int(nv)
  let q = int(qv)
  var initial: array[MaxN, int64]
  var ops: array[MaxQ, Operation]
  var cursor = 2 + n
  var answerCount = 0
  for i in 0 ..< n:
    initial[i] = input[2 + i]
    if initial[i] < -1000 or initial[i] > 1000: return -1
  for i in 0 ..< q:
    if cursor >= int(length): return -1
    let kind = input[cursor]
    inc cursor
    let words = if kind == 3: 4 elif kind >= 0 and kind <= 2: 3 else: 0
    if words == 0 or int(length) - cursor < words: return -1
    var op = Operation(kind: kind, left: input[cursor], right: input[cursor + 1], arg: input[cursor + 2], extra: 0)
    cursor += 3
    if kind == 3:
      op.extra = input[cursor]
      inc cursor
    if op.left < 0 or op.left > op.right or op.right >= nv: return -1
    if (kind <= 1 and (op.arg < -1000 or op.arg > 1000)) or
       (kind == 2 and (op.arg < 1 or op.arg > op.right - op.left + 1)) or
       (kind == 3 and (op.arg < 0 or op.arg > 8 or op.extra < 1 or op.extra > 1_000_000_000)): return -1
    if kind >= 2: inc answerCount
    ops[i] = op
  if cursor != int(length) or int(length) > 2 + MaxN + 5 * MaxQ: return -1
  let required = 8 * answerCount
  if required > 0 and (output == nil or capacity < csize_t(required)): return -2
  var runs: array[MaxRuns, Run]
  var runCount = 0
  for i in 0 ..< n:
    if runCount > 0 and runs[runCount - 1].value == initial[i]: runs[runCount - 1].right = int64(i)
    else:
      runs[runCount] = Run(left: int64(i), right: int64(i), value: initial[i])
      inc runCount
  var written = 0
  for oi in 0 ..< q:
    let op = ops[oi]
    if op.kind <= 1:
      splitAt(runs, runCount, op.right + 1, nv)
      splitAt(runs, runCount, op.left, nv)
      let start = lowerBound(runs, runCount, op.left)
      let finish = lowerBound(runs, runCount, op.right + 1)
      if op.kind == 0:
        let removed = finish - start
        let oldCount = runCount
        for i in finish ..< oldCount: runs[i - removed] = runs[i]
        runCount = oldCount - removed
        var i = runCount
        while i > start:
          runs[i] = runs[i - 1]
          dec i
        runs[start] = Run(left: op.left, right: op.right, value: op.arg)
        inc runCount
      else:
        for i in start ..< finish: runs[i].value += op.arg
      coalesce(runs, runCount)
    elif op.kind == 2:
      var ordered: array[MaxN, int64]
      var used = 0
      for i in 0 ..< runCount:
        let lo = max(runs[i].left, op.left)
        let hi = min(runs[i].right, op.right)
        if lo <= hi:
          for _ in lo .. hi:
            var at = used
            while at > 0 and ordered[at - 1] > runs[i].value:
              ordered[at] = ordered[at - 1]
              dec at
            ordered[at] = runs[i].value
            inc used
      storeLe(output, 8 * written, ordered[int(op.arg - 1)])
      inc written
    else:
      var total = 0'i64
      for i in 0 ..< runCount:
        let lo = max(runs[i].left, op.left)
        let hi = min(runs[i].right, op.right)
        if lo <= hi: total = (total + (hi - lo + 1) * modularPower(runs[i].value, op.arg, op.extra)) mod op.extra
      storeLe(output, 8 * written, total)
      inc written
  int64(required)
