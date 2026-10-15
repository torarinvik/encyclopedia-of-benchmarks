const MaxTransactions = 64
const MaxItems = 12
const MaxItemsets = 1 shl MaxItems
const SupportScale = 1_000_000'i64

proc itemCount(maskValue: int64): int =
  var mask = maskValue
  while mask != 0:
    result += int(mask and 1)
    mask = mask shr 1

proc supportIsFrequent(support, transactionCount, thresholdPpm: int64): bool =
  support * SupportScale >= thresholdPpm * transactionCount

proc apriori*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "apriori".} =
  if input == nil or length < 5: return -1
  let transactionCount = input[0]
  let items = input[1]
  let minSupportPpm = input[2]
  let minConfidencePpm = input[3]
  if transactionCount < 1 or transactionCount > MaxTransactions or items < 1 or items > MaxItems or
      minSupportPpm < 1 or minSupportPpm > SupportScale or minConfidencePpm < 0 or
      minConfidencePpm > SupportScale or length != csize_t(4 + transactionCount): return -1

  let maskLimit = 1'i64 shl int(items)
  var transactions: array[MaxTransactions, int64]
  for index in 0 ..< int(transactionCount):
    if input[index + 4] < 0 or input[index + 4] >= maskLimit: return -1
    transactions[index] = input[index + 4]

  var supports: array[MaxItemsets, int64]
  var previous, allFrequent, current: array[MaxItemsets, bool]
  var mask = 1'i64
  while mask < maskLimit:
    var support = 0'i64
    for transaction in 0 ..< int(transactionCount):
      if (transactions[transaction] and mask) == mask: support += 1
    if supportIsFrequent(support, transactionCount, minSupportPpm):
      supports[int(mask)] = support
      previous[int(mask)] = true
      allFrequent[int(mask)] = true
    mask = mask shl 1

  for size in 2 .. int(items):
    for index in 0 ..< MaxItemsets: current[index] = false
    var found = false
    for candidate in 1'i64 ..< maskLimit:
      if itemCount(candidate) != size: continue
      var allSubsetsFrequent = true
      for item in 0 ..< int(items):
        let bit = 1'i64 shl item
        if (candidate and bit) != 0 and not previous[int(candidate xor bit)]:
          allSubsetsFrequent = false
          break
      if not allSubsetsFrequent: continue
      var support = 0'i64
      for transaction in 0 ..< int(transactionCount):
        if (transactions[transaction] and candidate) == candidate: support += 1
      if supportIsFrequent(support, transactionCount, minSupportPpm):
        supports[int(candidate)] = support
        current[int(candidate)] = true
        allFrequent[int(candidate)] = true
        found = true
    previous = current
    if not found: break

  var ruleCount = 0'i64
  for candidate in 1'i64 ..< maskLimit:
    if not allFrequent[int(candidate)] or itemCount(candidate) < 2: continue
    var antecedent = (candidate - 1) and candidate
    while antecedent != 0:
      if supports[int(candidate)] * SupportScale >= minConfidencePpm * supports[int(antecedent)]:
        ruleCount += 1
      antecedent = (antecedent - 1) and candidate
  ruleCount
