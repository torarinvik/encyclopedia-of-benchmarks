const
  MaxLimit = 100000'i64
  MaxParseableLength = 2
  WordCount = 1563

proc digitSum10(value: int64): int64 =
  var remaining = value
  var total = 0'i64
  while remaining > 0:
    total += remaining mod 10
    remaining = remaining div 10
  total

proc self_number_count_sieve*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "self_number_count_sieve".} =
  if input.isNil or length < 1 or length > csize_t(MaxParseableLength): return -1
  let limit = input[0]
  if length != 1 or limit < 1 or limit > MaxLimit: return -1

  var generated: array[WordCount, uint64]
  for source in 1'i64 .. limit:
    let target = source + digitSum10(source)
    if target <= limit:
      generated[int(target div 64)] = generated[int(target div 64)] or (1'u64 shl int(target mod 64))
  var count = 0'i64
  for value in 1'i64 .. limit:
    if (generated[int(value div 64)] and (1'u64 shl int(value mod 64))) == 0: inc count
  count
