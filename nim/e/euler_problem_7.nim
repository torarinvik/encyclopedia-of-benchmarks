const SieveLimit = 1_000_000
const MaxOrdinal = 10_001'i64
const MaxValidInputLength = 1
const MaxParseableInputLength = 2

proc euler_problem_7*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "euler_problem_7".} =
  if input.isNil or length < csize_t(MaxValidInputLength) or
      length > csize_t(MaxParseableInputLength): return -1
  if length != csize_t(MaxValidInputLength): return -1
  let ordinal = input[0]
  if ordinal < 1'i64 or ordinal > MaxOrdinal: return -1

  var composite = newSeq[bool](SieveLimit)
  var count = 0'i64
  for candidate in 2 ..< SieveLimit:
    if not composite[candidate]:
      inc count
      if count == ordinal: return int64(candidate)
      var multiple = candidate * 2
      while multiple < SieveLimit:
        composite[multiple] = true
        multiple += candidate
  -1
