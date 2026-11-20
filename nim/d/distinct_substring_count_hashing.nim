const MaxText = 64
const MaxInputLength = 66
const HashModulus = 1_000_000_007'i64

proc distinct_substring_count_hashing*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "distinct_substring_count_hashing".} =
  if input.isNil or length < 1 or length > MaxInputLength: return -1
  let nValue = input[0]
  if nValue < 0 or nValue > MaxText or length != csize_t(nValue + 1): return -1
  let n = int(nValue)
  for i in 0 ..< n:
    if input[i + 1] < 0 or input[i + 1] > 255: return -1

  var prefix: array[65, int64]
  var powers: array[65, int64]
  powers[0] = 1
  for i in 0 ..< n:
    prefix[i + 1] = (prefix[i] * 257 + input[i + 1] + 1) mod HashModulus
    powers[i + 1] = powers[i] * 257 mod HashModulus

  var groupHash: array[64, int64]
  var groupHead: array[64, int64]
  var representativeStart: array[64, int64]
  var representativeNext: array[64, int64]
  var distinct = 0'i64
  for width in 1 .. n:
    for slot in 0 ..< 64:
      groupHash[slot] = -1
      groupHead[slot] = -1
    var representativeCount = 0
    for start in 0 .. n - width:
      let endIndex = start + width
      var fingerprint = (prefix[endIndex] - prefix[start] * powers[width] mod HashModulus) mod HashModulus
      if fingerprint < 0: fingerprint += HashModulus
      var slot = int(fingerprint mod 64)
      while groupHash[slot] != -1 and groupHash[slot] != fingerprint:
        slot = (slot + 1) mod 64
      if groupHash[slot] == -1: groupHash[slot] = fingerprint

      var duplicate = false
      var prior = groupHead[slot]
      while prior >= 0:
        let oldStart = int(representativeStart[int(prior)])
        var offset = 0
        while offset < width and input[start + offset + 1] == input[oldStart + offset + 1]: inc offset
        if offset == width:
          duplicate = true
          break
        prior = representativeNext[int(prior)]
      if not duplicate:
        representativeStart[representativeCount] = int64(start)
        representativeNext[representativeCount] = groupHead[slot]
        groupHead[slot] = int64(representativeCount)
        inc representativeCount
        inc distinct
  distinct
