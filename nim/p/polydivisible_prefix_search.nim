## Count a bounded tree of valid one-digit extensions.

proc polydivisibleExtend(prefix, digits, base, maxDigits: int64): int64 =
  var count = 1'i64
  if digits == maxDigits: return count
  let nextLength = digits + 1
  for digit in 0 ..< int(base):
    let candidate = prefix * base + int64(digit)
    if candidate mod nextLength == 0:
      count += polydivisibleExtend(candidate, nextLength, base, maxDigits)
  count

proc polydivisible_prefix_search*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "polydivisible_prefix_search".} =
  if input.isNil or length != 2: return -1
  let base = input[0]
  let maxDigits = input[1]
  if base < 2 or base > 10 or maxDigits < 1 or maxDigits > 6: return -1
  var count = 0'i64
  for firstDigit in 1 ..< int(base):
    count += polydivisibleExtend(int64(firstDigit), 1, base, maxDigits)
  count
