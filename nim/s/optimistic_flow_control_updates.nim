const MaxN = 3
const MaxL = 4
const MaxInput = 20
const MaxOutput = 48
const MaxUpdates = 6
const Scale = 46656'i64

proc gcd64(a0, b0: int64): int64 =
  var a = a0
  var b = b0
  while b != 0:
    let r = a mod b
    a = b
    b = r
  a

proc put64(output: ptr UncheckedArray[uint8], position: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[position+byte] = uint8((bits shr (8*byte)) and 255)

proc optimistic_flow_control_updates*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "optimistic_flow_control_updates".} =
  if input.isNil or length < csize_t(7) or length > csize_t(MaxInput): return -1
  let n64 = input[0]
  let l64 = input[1]
  let mode64 = input[2]
  let q64 = input[3]
  if n64 < 2 or n64 > MaxN or l64 < 1 or l64 > MaxL or mode64 < 0 or mode64 > 3 or q64 < 1 or q64 > MaxUpdates: return -1
  let n = int(n64)
  let links = int(l64)
  let mode = int(mode64)
  let updates = int(q64)
  if int64(length) != int64(4+links+n*links): return -1
  var cap: array[MaxL, int64]
  var path: array[MaxN, array[MaxL, bool]]
  var rate: array[MaxN, int64]
  for e in 0 ..< links:
    cap[e] = input[4+e]
    if cap[e] < 1 or cap[e] > 16: return -1
  for s in 0 ..< n:
    var used = false
    for e in 0 ..< links:
      let bit = input[4+links+s*links+e]
      if bit != 0 and bit != 1: return -1
      path[s][e] = bit == 1
      used = used or bit == 1
    if not used: return -1
  let outputBytes = 16*n
  if output.isNil or capacity < csize_t(outputBytes): return -2
  for step in 0 ..< updates:
    var session = 0
    if mode == 0: session = step mod n
    elif mode == 1:
      for s in 1 ..< n:
        if rate[s] < rate[session]: session = s
    elif mode == 2:
      var found = false
      for s in 0 ..< n:
        if not found:
          var local = true
          for j in 0 ..< n:
            if j != s and local:
              var shares = false
              for e in 0 ..< links: shares = shares or (path[s][e] and path[j][e])
              if shares and (rate[j] < rate[s] or (rate[j] == rate[s] and j < s)): local = false
          if local: session = s; found = true
    else:
      var selected = links
      var bestLoad = 0'i64
      for e in 0 ..< links:
        var load = 0'i64
        var used = false
        for s in 0 ..< n:
          if path[s][e]: load += rate[s]; used = true
        if used and (selected == links or load*cap[selected] > bestLoad*cap[e]):
          selected = e; bestLoad = load
      for s in 0 ..< n:
        if path[s][selected]: session = s; break
    var best = high(int64)
    var bottleneck = links
    for e in 0 ..< links:
      if path[session][e]:
        var fixed = 0'i64
        var active = 1
        for j in 0 ..< n:
          if j != session and path[j][e]:
            if rate[j] <= rate[session]: fixed += rate[j] else: inc active
        var level = rate[session]
        var candidate = level
        for pass in 0 ..< n:
          let numerator = cap[e]*Scale-fixed
          if numerator < 0 or numerator mod int64(active) != 0: return -1
          candidate = numerator div int64(active)
          if candidate < level: return -1
          var next = high(int64)
          for j in 0 ..< n:
            if j != session and path[j][e] and rate[j] > level and rate[j] < next: next = rate[j]
          if next == high(int64) or candidate <= next: break
          var saturated = 0
          for j in 0 ..< n:
            if j != session and path[j][e] and rate[j] == next: inc saturated
          fixed += int64(saturated)*next
          active -= saturated
          level = next
        if candidate < best: best = candidate; bottleneck = e
    if bottleneck == links: return -1
    rate[session] = best
    for j in 0 ..< n:
      if j != session and path[j][bottleneck] and rate[j] > best: rate[j] = best
  var staged: array[MaxOutput, uint8]
  for s in 0 ..< n:
    let divisor = gcd64(rate[s], Scale)
    put64(addr staged[0], 16*s, rate[s] div divisor)
    put64(addr staged[0], 16*s+8, Scale div divisor)
  for byte in 0 ..< outputBytes: output[byte] = staged[byte]
  int64(outputBytes)
