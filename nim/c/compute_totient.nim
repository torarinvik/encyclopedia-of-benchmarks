## Encode phi(1) through phi(n) as comma-separated decimal bytes.
proc decimalLength(value: int64): csize_t =
  var remaining = value
  var length = csize_t(1)
  while remaining >= 10:
    remaining = remaining div 10
    inc length
  length

proc appendDecimal(valueInput: int64, output: ptr UncheckedArray[uint8], positionInput: csize_t): csize_t =
  var value = valueInput
  var digits: array[3, uint8]
  var count = 0
  while true:
    digits[count] = uint8(value mod 10)
    inc count
    value = value div 10
    if value == 0: break
  var position = positionInput
  while count > 0:
    dec count
    output[position] = uint8(ord('0')) + digits[count]
    inc position
  position

proc compute_totient*(n: int64, output: ptr UncheckedArray[uint8],
                      outputCapacity: csize_t): int64 {.cdecl, exportc: "compute_totient".} =
  if n < 1 or n > 80: return -1
  var phi: array[80, int64]
  for i in 1'i64 .. n: phi[int(i - 1)] = i
  for p in 2'i64 .. n:
    if phi[int(p - 1)] != p: continue
    phi[int(p - 1)] = p - 1
    var i = 2 * p
    while i <= n:
      phi[int(i - 1)] = (phi[int(i - 1)] div p) * (p - 1)
      i += p
  var required = csize_t(n - 1)
  for i in 0 ..< int(n): required += decimalLength(phi[i])
  if output.isNil or outputCapacity < required: return -2
  var position = csize_t(0)
  for i in 0 ..< int(n):
    if i > 0:
      output[position] = uint8(ord(','))
      inc position
    position = appendDecimal(phi[i], output, position)
  int64(position)
