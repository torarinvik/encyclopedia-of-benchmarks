const
  MaxN = 16
  Modulus = 998_244_353'i64

proc stirling_number_of_the_second_kind*(input: ptr UncheckedArray[int64],
    length: csize_t): int64 {.cdecl, exportc: "stirling_number_of_the_second_kind".} =
  if input.isNil or length != csize_t(1): return -1
  let nValue = input[0]
  if nValue < 0 or nValue > MaxN.int64: return -1
  let n = int(nValue)

  var row: array[MaxN + 1, int64]
  row[0] = 1
  var currentN = 1
  while currentN <= n:
    var k = currentN
    while k > 0:
      row[k] = (row[k - 1] + k.int64 * row[k]) mod Modulus
      dec k
    row[0] = 0
    inc currentN

  var result = 0'i64
  for k in 0..n:
    let next = (k + 1).int64
    let weight = next * next * next
    result = (result + weight * row[k]) mod Modulus
  result
