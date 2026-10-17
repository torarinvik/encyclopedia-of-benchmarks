const MaxInputValues = 131
const MaxValidators = 128
const MaxStake = 1_000_000'i64
const MaxTotalStake = 128_000_000'i64

proc roulette_wheel_selection*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "roulette_wheel_selection".} =
  if input == nil or length < 3 or length > csize_t(MaxInputValues): return -1
  let countValue = input[0]
  if countValue < 1 or countValue > MaxValidators.int64: return -1
  let count = int(countValue)
  if length != csize_t(count + 2): return -1

  var total = 0'i64
  for index in 0 ..< count:
    let stake = input[1 + index]
    if stake < 1 or stake > MaxStake: return -1
    if total > MaxTotalStake - stake: return -1
    total += stake

  let ticket = input[1 + count]
  if ticket < 0 or ticket >= total: return -1

  var cumulative = 0'i64
  for index in 0 ..< count:
    cumulative += input[1 + index]
    if ticket < cumulative: return int64(index + 1)
  -1
