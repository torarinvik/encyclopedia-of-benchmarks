const MaxInput = 67_108_863'i64

proc highestPowerPosition(value: int64): int =
  var position = 0
  var power = 1'i64
  while power <= value div 2:
    power *= 2
    inc position
  position

proc countSetBitsRecursive(value: int64): int64 =
  if value == 0: return 0
  let position = highestPowerPosition(value)
  let power = 1'i64 shl position
  let bitsAtPosition = if position == 0: 0'i64 else: int64(position) * (power shr 1)
  let remainingNumbers = value - power + 1
  bitsAtPosition + remainingNumbers + countSetBitsRecursive(value - power)

## Count set bits across every integer from 1 through value, inclusive.
proc count_set_bits*(value: int64): int64 {.cdecl, exportc: "count_set_bits".} =
  if value < 0 or value > MaxInput: return -1
  countSetBitsRecursive(value)
