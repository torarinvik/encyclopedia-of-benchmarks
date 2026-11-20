const MaxLength = 10
const MaxSupport = 11

proc chooseValue(total, selected0: int): int64 =
  if total < 0 or selected0 < 0 or selected0 > total: return 0
  let selected = min(selected0, total - selected0)
  var value = 1'i64
  for factor in 1 .. selected:
    value = value * int64(total - selected + factor) div int64(factor)
  value

proc multinomial3(total, first, second: int): int64 =
  if total < 0 or first < 0 or second < 0 or first > total or second > total or
      first + second > total: return 0
  chooseValue(total, first) * chooseValue(total - first, second)

proc gcdValue(left0, right0: int64): int64 =
  var left = left0
  var right = right0
  while right != 0:
    let remainder = left mod right
    left = right
    right = remainder
  left

proc putI64Le(output: ptr UncheckedArray[uint8], word: int, value: int64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[word * 8 + byte] = uint8(bits and 255'u64)
    bits = bits shr 8

proc spatial_motif_different_type_contact_pmf*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "spatial_motif_different_type_contact_pmf".} =
  if input == nil or length != 5: return -1
  let n0 = input[0]
  let x10 = input[1]
  let y10 = input[2]
  let x20 = input[3]
  let y20 = input[4]
  if n0 < 1 or n0 > MaxLength or x10 < 0 or y10 < 0 or x20 < 0 or y20 < 0 or
      x10 > n0 or y10 > n0 or x20 > n0 or y20 > n0: return -1
  if x10 + y10 > n0 or x20 + y20 > n0: return -1

  let n = int(n0)
  let x1 = int(x10)
  let y1 = int(y10)
  let x2 = int(x20)
  let y2 = int(y20)
  let neither1 = n - x1 - y1
  let denominator = multinomial3(n, x2, y2)
  var numerators: array[MaxSupport, int64]
  for contacts in 0 .. n:
    for xx in 0 .. x1:
      for xy in 0 .. (x1 - xx):
        let yx = contacts - xy
        if yx < 0 or yx > y1: continue
        for yy in 0 .. (y1 - yx):
          numerators[contacts] += multinomial3(x1, xx, xy) *
            multinomial3(y1, yx, yy) *
            multinomial3(neither1, x2 - xx - yx, y2 - xy - yy)

  var expectedNumerator = 0'i64
  for contacts in 0 .. n:
    expectedNumerator += int64(contacts) * numerators[contacts]
  var expectedDenominator = denominator
  let divisor = gcdValue(expectedNumerator, expectedDenominator)
  expectedNumerator = expectedNumerator div divisor
  expectedDenominator = expectedDenominator div divisor
  let bytes = (n + 5) * 8
  if output == nil or capacity < csize_t(bytes): return -2
  putI64Le(output, 0, int64(n))
  putI64Le(output, 1, denominator)
  for contacts in 0 .. n: putI64Le(output, contacts + 2, numerators[contacts])
  putI64Le(output, n + 3, expectedNumerator)
  putI64Le(output, n + 4, expectedDenominator)
  int64(bytes)
