type
  Plan = object
    open, close, start, step, pad, count: int
    letter: bool
  Endpoint = object
    valid, letter, upper: bool
    value, width: int

proc endpoint(p: ptr UncheckedArray[int64], first, last: int): Endpoint =
  let n = last - first
  if n == 1 and ((p[first] >= 65 and p[first] <= 90) or
                 (p[first] >= 97 and p[first] <= 122)):
    return Endpoint(valid: true, letter: true, upper: p[first] <= 90,
                    value: int(p[first]), width: 1)
  if n < 1 or n > 4: return
  var value = 0
  for i in first ..< last:
    if p[i] < 48 or p[i] > 57: return
    value = value * 10 + int(p[i] - 48)
  Endpoint(valid: true, value: value, width: n)

proc parseStep(p: ptr UncheckedArray[int64], first, last: int): int =
  var at = first
  var sign = 1
  if at < last and (p[at] == 43 or p[at] == 45):
    if p[at] == 45: sign = -1
    inc at
  if last - at < 1: return 0
  var value = 0
  for i in at ..< last:
    if p[i] < 48 or p[i] > 57: return 0
    if value < 10000:
      value = value * 10 + int(p[i] - 48)
      if value > 10000: value = 10000
  if value == 0: return 0
  sign * value

proc makePlan(p: ptr UncheckedArray[int64], n: int): tuple[ok: bool, plan: Plan] =
  if n < 1 or n > 64: return
  var open = -1
  var close = -1
  for i in 0 ..< n:
    if p[i] < 32 or p[i] > 126: return
    if p[i] == 123:
      if open >= 0: return
      open = i
    elif p[i] == 125:
      if close >= 0: return
      close = i
  if open < 0 or close <= open or open + n - close - 1 > 32: return
  var sep1 = -1
  var sep2 = -1
  var i = open + 1
  while i + 1 < close:
    if p[i] == 46 and p[i + 1] == 46:
      if sep1 < 0: sep1 = i
      elif sep2 < 0: sep2 = i
      else: return
      i += 2
    else:
      inc i
  if sep1 < 0: return
  let a = endpoint(p, open + 1, sep1)
  let b = endpoint(p, sep1 + 2, (if sep2 < 0: close else: sep2))
  if not a.valid or not b.valid or a.letter != b.letter or
     (a.letter and a.upper != b.upper): return
  var step = 0
  if sep2 < 0:
    step = (if a.value <= b.value: 1 else: -1)
  else:
    step = parseStep(p, sep2 + 2, close)
  if step == 0 or (a.value < b.value and step < 0) or
     (a.value > b.value and step > 0): return
  var count = 1
  if a.value < b.value: count = (b.value - a.value) div step + 1
  elif a.value > b.value: count = (a.value - b.value) div (-step) + 1
  if count > 16: return
  var pad = 0
  if not a.letter and (p[open + 1] == 48 or p[sep1 + 2] == 48):
    pad = max(a.width, b.width)
  (true, Plan(open: open, close: close, start: a.value, step: step,
              pad: pad, count: count, letter: a.letter))

proc brace_range_expansion*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "brace_range_expansion".} =
  if input.isNil or length < 2 or length > 65: return -1
  let nValue = input[0]
  if nValue < 1 or nValue > 64 or length != csize_t(nValue + 1): return -1
  let n = int(nValue)
  let parsed = makePlan(cast[ptr UncheckedArray[int64]](addr input[1]), n)
  if not parsed.ok: return -1
  let plan = parsed.plan
  var staged: array[591, uint8]
  var out = 0
  var value = plan.start
  let suffixStart = plan.close + 1
  for item in 0 ..< plan.count:
    if item != 0:
      staged[out] = 0
      inc out
    for j in 0 ..< plan.open:
      staged[out] = uint8(input[j + 1])
      inc out
    if plan.letter:
      staged[out] = uint8(value)
      inc out
    else:
      var digits: array[4, int]
      var used = 0
      var remaining = value
      while true:
        digits[used] = remaining mod 10
        inc used
        remaining = remaining div 10
        if remaining == 0: break
      while used < plan.pad:
        staged[out] = 48
        inc out
      while used > 0:
        dec used
        staged[out] = uint8(48 + digits[used])
        inc out
    var j = suffixStart
    while j < n:
      staged[out] = uint8(input[j + 1])
      inc out
      inc j
    value += plan.step
  if output.isNil or capacity < csize_t(out): return -2
  for j in 0 ..< out: output[j] = staged[j]
  int64(out)
