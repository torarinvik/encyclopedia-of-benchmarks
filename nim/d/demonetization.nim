## Count denomination combinations with the source's recursive recurrence.
const MaxAmount = 30'i64
const MaxDenominations = 4'i64

proc ways(amount: int64, input: ptr UncheckedArray[int64], count: int64): int64 =
  if amount < 0 or count < 0: return 0
  if amount == 0: return 1
  if count == 0: return 0
  let denomination = input[int(count + 1)]
  ways(amount, input, count - 1) + ways(amount - denomination, input, count)

proc demonetization*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "demonetization".} =
  if input == nil or length < 2 or length > csize_t(MaxDenominations + 2): return -1
  let amount = input[0]
  let count = input[1]
  if amount < -MaxAmount or amount > MaxAmount or count < 0 or count > MaxDenominations
      or length != csize_t(count + 2): return -1
  for index in 0 ..< int(count):
    if input[index + 2] < 1 or input[index + 2] > MaxAmount: return -1
  ways(amount, input, count)
