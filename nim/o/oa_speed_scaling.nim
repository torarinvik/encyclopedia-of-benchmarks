const MaxJobs = 2
const MaxInput = 8
const MaxOutput = 152

type Rat = object
  n, d: int64
type Segment = object
  start, finish, speedN, speedD: int64

proc gcd64(a0, b0: int64): int64 =
  var a = a0
  var b = b0
  while b != 0:
    let r = a mod b
    a = b
    b = r
  if a < 0: -a else: a

proc makeRat(n0, d0: int64): Rat =
  var n = n0
  var d = d0
  if d < 0: n = -n; d = -d
  let g = gcd64(n, d)
  Rat(n: n div g, d: d div g)

proc ratInt(x: int64): Rat = Rat(n: x, d: 1)
proc ratAdd(a, b: Rat): Rat = makeRat(a.n*b.d + b.n*a.d, a.d*b.d)
proc ratSub(a, b: Rat): Rat = makeRat(a.n*b.d - b.n*a.d, a.d*b.d)
proc ratMul(a, b: Rat): Rat = makeRat(a.n*b.n, a.d*b.d)
proc ratDiv(a, b: Rat): Rat = makeRat(a.n*b.d, a.d*b.n)
proc ratCmp(a, b: Rat): int =
  let left = a.n*b.d
  let right = b.n*a.d
  if left > right: 1 elif left < right: -1 else: 0

proc put64(output: ptr UncheckedArray[uint8], at: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[at+byte] = uint8((bits shr (8*byte)) and 255)

proc appendSegment(segments: var array[3, Segment], count: var int,
                   start, finish: int64, speed: Rat) =
  if finish <= start or speed.n <= 0: return
  if count > 0 and segments[count-1].finish == start and
      ratCmp(speed, makeRat(segments[count-1].speedN, segments[count-1].speedD)) == 0:
    segments[count-1].finish = finish
    return
  segments[count] = Segment(start: start, finish: finish,
                            speedN: speed.n, speedD: speed.d)
  inc count

proc oa_speed_scaling*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "oa_speed_scaling".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxInput): return -1
  let count64 = input[0]
  if count64 < 1 or count64 > int64(MaxJobs): return -1
  let n = int(count64)
  if int64(length) != int64(1 + 3*n): return -1
  var release, deadline: array[MaxJobs, int64]
  var work: array[MaxJobs, int64]
  var remaining, completion: array[MaxJobs, Rat]
  var completed: array[MaxJobs, bool]
  for j in 0 ..< n:
    release[j] = input[1+3*j]
    deadline[j] = input[2+3*j]
    work[j] = input[3+3*j]
    if release[j] < 0 or release[j] >= deadline[j] or deadline[j] > 4 or
        work[j] < 1 or work[j] > 4: return -1
    remaining[j] = ratInt(0)
    completion[j] = ratInt(0)

  var segments: array[3, Segment]
  var segmentCount = 0
  var energy = ratInt(0)
  for now in 0'i64 .. 4'i64:
    var hasArrival = false
    for j in 0 ..< n:
      if release[j] == now:
        remaining[j] = ratInt(work[j])
        hasArrival = true
    if not hasArrival: continue
    var nextRelease = 5'i64
    for j in 0 ..< n:
      if release[j] > now and release[j] < nextRelease: nextRelease = release[j]

    var order: array[MaxJobs, int]
    var used = 0
    for j in 0 ..< n:
      if remaining[j].n > 0 and deadline[j] > now:
        order[used] = j
        inc used
    for i in 1 ..< used:
      let value = order[i]
      var k = i
      while k > 0 and (deadline[order[k-1]] > deadline[value] or
          (deadline[order[k-1]] == deadline[value] and order[k-1] > value)):
        order[k] = order[k-1]
        dec k
      order[k] = value

    var left = now
    while used > 0:
      var prefix = ratInt(0)
      var best = ratInt(0)
      var bestCount = 0
      for k in 1 .. used:
        prefix = ratAdd(prefix, remaining[order[k-1]])
        let density = ratDiv(prefix, ratInt(deadline[order[k-1]]-left))
        if bestCount == 0 or ratCmp(density, best) > 0:
          best = density
          bestCount = k
      let right = deadline[order[bestCount-1]]
      let stop = min(right, nextRelease)
      appendSegment(segments, segmentCount, left, stop, best)
      energy = ratAdd(energy, ratMul(ratMul(ratMul(best,best),best),ratInt(stop-left)))
      var cursor = ratInt(left)
      let stopRat = ratInt(stop)
      for k in 0 ..< bestCount:
        let j = order[k]
        let finish = ratAdd(cursor,ratDiv(remaining[j],best))
        if ratCmp(finish,stopRat) <= 0:
          completion[j] = finish
          completed[j] = true
          remaining[j] = ratInt(0)
          cursor = finish
        else:
          remaining[j] = ratSub(remaining[j],ratMul(best,ratSub(stopRat,cursor)))
          cursor = stopRat
          break
      if stop < right: break
      for k in bestCount ..< used: order[k-bestCount] = order[k]
      used -= bestCount
      left = right

  for j in 0 ..< n:
    if not completed[j]: return -1
  var values: array[19, int64]
  var fields = 0
  values[fields] = int64(segmentCount); inc fields
  values[fields] = energy.n; inc fields
  values[fields] = energy.d; inc fields
  for s in 0 ..< segmentCount:
    values[fields] = segments[s].start; inc fields
    values[fields] = segments[s].finish; inc fields
    values[fields] = segments[s].speedN; inc fields
    values[fields] = segments[s].speedD; inc fields
  for j in 0 ..< n:
    values[fields] = completion[j].n; inc fields
    values[fields] = completion[j].d; inc fields
  let outputBytes = 8*fields
  if output.isNil or capacity < csize_t(outputBytes): return -2
  var staged: array[MaxOutput, uint8]
  for i in 0 ..< fields: put64(addr staged[0],8*i,values[i])
  for i in 0 ..< outputBytes: output[i] = staged[i]
  int64(outputBytes)
