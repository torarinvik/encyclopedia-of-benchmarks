const
  PrefixModulus = 998_244_353'i64
  PrefixMaxT = 16
  PrefixMaxN = 128
  PrefixMaxInputLength = 34

proc prefix_sum_of_binomial_coefficient*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "prefix_sum_of_binomial_coefficient".} =
  if input.isNil or length < csize_t(3) or length > csize_t(PrefixMaxInputLength): return -1
  let countValue = input[0]
  if countValue < 1 or countValue > PrefixMaxT.int64: return -1
  let count = int(countValue)
  if int(length) != 1 + 2 * count: return -1
  var ns: array[PrefixMaxT, int64]
  var ks: array[PrefixMaxT, int64]
  for query in 0 ..< count:
    ns[query] = input[1 + 2 * query]
    ks[query] = input[2 + 2 * query]
    if ns[query] < 0 or ns[query] > PrefixMaxN.int64 or ks[query] < 0 or ks[query] > ns[query]:
      return -1
  let outputLength = 4 * count
  if output.isNil or capacity < csize_t(outputLength): return -2

  var inverse: array[PrefixMaxN + 1, int64]
  inverse[1] = 1
  for value in 2 .. PrefixMaxN:
    inverse[value] = PrefixModulus - (PrefixModulus div int64(value)) *
      inverse[int(PrefixModulus mod int64(value))] mod PrefixModulus
  for query in 0 ..< count:
    var coefficient = 1'i64
    var prefix = 1'i64
    for index in 0 ..< int(ks[query]):
      coefficient = coefficient * (ns[query] - int64(index)) mod PrefixModulus
      coefficient = coefficient * inverse[index + 1] mod PrefixModulus
      prefix = (prefix + coefficient) mod PrefixModulus
    let offset = 4 * query
    output[offset] = uint8(prefix mod 256)
    output[offset + 1] = uint8((prefix div 256) mod 256)
    output[offset + 2] = uint8((prefix div 65_536) mod 256)
    output[offset + 3] = uint8(prefix div 16_777_216)
  int64(outputLength)
