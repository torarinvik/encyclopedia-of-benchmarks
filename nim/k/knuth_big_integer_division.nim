import std/ffi: csize_t

const
  Base = 1_000_000_000'i64
  MaxLimbs = 8
  MaxInput = 130
  MaxOutput = 129

type Limbs = array[MaxLimbs, int64]

proc trim(x: Limbs, countInput: int): int =
  var count = countInput
  while count > 0 and x[count - 1] == 0: dec count
  count

proc parseLimbs(text: ptr UncheckedArray[int64], length: int, x: var Limbs): int =
  var count = 0
  for at in 0 ..< length:
    var carry = text[at] - 48
    for i in 0 ..< count:
      carry += x[i] * 10
      x[i] = carry mod Base
      carry = carry div Base
    if carry != 0:
      x[count] = carry
      inc count
    if count == 0: count = 1
  trim(x, count)

proc compare(a: Limbs, na: int, b: Limbs, nb: int): int =
  if na != nb: return (if na > nb: 1 else: -1)
  for i in countdown(na - 1, 0):
    if a[i] != b[i]: return (if a[i] > b[i]: 1 else: -1)
  0

proc divideLimbs(a: Limbs, na: int, b: Limbs, nb: int,
                 q: var Limbs, r: var Limbs): (int, int) =
  if na == 0: return (0, 0)
  if compare(a, na, b, nb) < 0:
    r = a
    return (0, na)
  if nb == 1:
    var rem = 0'i64
    for i in countdown(na - 1, 0):
      let current = rem * Base + a[i]
      q[i] = current div b[0]
      rem = current mod b[0]
    if rem != 0: r[0] = rem
    return (trim(q, na), (if rem != 0: 1 else: 0))

  var v: array[MaxLimbs, int64]
  var u: array[MaxLimbs + 1, int64]
  let scale = Base div (b[nb - 1] + 1)
  var carry = 0'i64
  for i in 0 ..< nb:
    let current = b[i] * scale + carry
    v[i] = current mod Base
    carry = current div Base
  carry = 0
  for i in 0 ..< na:
    let current = a[i] * scale + carry
    u[i] = current mod Base
    carry = current div Base
  u[na] = carry
  let width = na - nb + 1
  for step in countdown(width - 1, 0):
    let numerator = u[step + nb] * Base + u[step + nb - 1]
    var estimate = numerator div v[nb - 1]
    var remEstimate = numerator mod v[nb - 1]
    if estimate >= Base:
      estimate = Base - 1
      remEstimate = numerator - estimate * v[nb - 1]
    while remEstimate < Base and estimate * v[nb - 2] > remEstimate * Base + u[step + nb - 2]:
      dec estimate
      remEstimate += v[nb - 1]
    var borrow = 0'i64
    for i in 0 ..< nb:
      let product = estimate * v[i] + borrow
      let low = product mod Base
      borrow = product div Base
      var diff = u[step + i] - low
      if diff < 0:
        diff += Base
        inc borrow
      u[step + i] = diff
    let top = u[step + nb] - borrow
    if top < 0:
      dec estimate
      carry = 0
      for i in 0 ..< nb:
        var total = u[step + i] + v[i] + carry
        if total >= Base:
          total -= Base
          carry = 1
        else:
          carry = 0
        u[step + i] = total
      u[step + nb] = top + carry
    else:
      u[step + nb] = top
    q[step] = estimate
  carry = 0
  for i in countdown(nb - 1, 0):
    let current = carry * Base + u[i]
    r[i] = current div scale
    carry = current mod scale
  (trim(q, width), trim(r, nb))

proc emit(x: Limbs, countInput: int, output: ptr UncheckedArray[uint8], atInput: int): int =
  var count = trim(x, countInput)
  var at = atInput
  if count == 0:
    output[at] = 48
    return at + 1
  var value = x[count - 1]
  var power = 1'i64
  while value div power >= 10: power *= 10
  while power > 0:
    output[at] = uint8(48 + value div power mod 10)
    inc at
    power = power div 10
  while count > 1:
    dec count
    value = x[count - 1]
    power = Base div 10
    while power > 0:
      output[at] = uint8(48 + value div power mod 10)
      inc at
      power = power div 10
  at

proc knuth_big_integer_division*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "knuth_big_integer_division".} =
  if input.isNil or length < csize_t(4) or length > csize_t(MaxInput): return -1
  if input[0] < 1 or input[0] > 64 or input[1] < 1 or input[1] > 64: return -1
  let naText = int(input[0])
  let nbText = int(input[1])
  if int(length) != 2 + naText + nbText: return -1
  let aText = cast[ptr UncheckedArray[int64]](cast[uint](input) + uint(16))
  let bText = cast[ptr UncheckedArray[int64]](cast[uint](input) + uint(16 * (2 + naText)))
  for i in 0 ..< naText:
    if aText[i] < 48 or aText[i] > 57: return -1
  for i in 0 ..< nbText:
    if bText[i] < 48 or bText[i] > 57: return -1
  if (naText > 1 and aText[0] == 48) or (nbText > 1 and bText[0] == 48) or (nbText == 1 and bText[0] == 48): return -1

  var a, b, q, r: Limbs
  let na = parseLimbs(aText, naText, a)
  let nb = parseLimbs(bText, nbText, b)
  let (nq, nr) = divideLimbs(a, na, b, nb, q, r)
  var staged: array[MaxOutput, uint8]
  var bytes = emit(q, nq, cast[ptr UncheckedArray[uint8]](addr staged[0]), 0)
  staged[bytes] = 58
  inc bytes
  bytes = emit(r, nr, cast[ptr UncheckedArray[uint8]](addr staged[0]), bytes)
  if output.isNil or int(capacity) < bytes: return -2
  for i in 0 ..< bytes: output[i] = staged[i]
  int64(bytes)
