## Reduce the input array to its minimum with a sign-bit mask.
const MaxLength = 4096
const MaxValue = 2_147_483_647'i64

proc bitwisemin*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "bitwisemin".} =
  if length == 0 or length > csize_t(MaxLength) or values == nil: return -1
  var minimum = values[0]
  if minimum < 0 or minimum > MaxValue: return -1
  for index in 1 ..< int(length):
    let value = values[index]
    if value < 0 or value > MaxValue: return -1
    let difference = minimum - value
    let sign = (difference and 0xFFFF_FFFF'i64) shr 31
    let keepMinimum = 0xFFFF_FFFF'u32 * uint32(sign)
    minimum = int64((uint32(minimum) and keepMinimum) or (uint32(value) and not keepMinimum))
  minimum
