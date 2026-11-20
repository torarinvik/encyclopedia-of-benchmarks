const MaxModulus = 64'i64
const MaxInputLength = 2

proc pisano_period*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "pisano_period".} =
  if input == nil or length < 1 or length > csize_t(MaxInputLength): return -1
  if length != 1 or input[0] < 1 or input[0] > MaxModulus: return -1
  let modulus = input[0]
  let initialNext = 1'i64 mod modulus
  var previous = 0'i64
  var current = initialNext
  for period in 1'i64 .. 6 * modulus:
    let next = (previous + current) mod modulus
    previous = current
    current = next
    if previous == 0 and current == initialNext: return period
  -1
