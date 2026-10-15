## Count ASCII vowels and consonants, packing both counts into one i64.
const CountBase = 4_294_967_296'i64

proc count_vowels_consonants*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "count_vowels_consonants".} =
  if length > 100_000 or (length != 0 and values == nil): return -1
  var vowels: int64 = 0
  var consonants: int64 = 0
  for index in 0 ..< length:
    let code = values[index]
    if code < 0 or code > 127: return -1
    if (code >= 65 and code <= 90) or (code >= 97 and code <= 122):
      let letter = code or 32
      if letter == 97 or letter == 101 or letter == 105 or letter == 111 or letter == 117:
        inc vowels
      else:
        inc consonants
  vowels * CountBase + consonants
