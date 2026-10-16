const MaxN = 4096
const FnvOffset = 14695981039346656037'u64
const FnvPrime = 1099511628211'u64

proc hashI32(hashValue: var uint64, value: int64) =
  let bits = cast[uint32](int32(value))
  for shift in countup(0, 24, 8):
    hashValue = (hashValue xor uint64(uint8(bits shr shift))) *% FnvPrime

proc monotonic_queue*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "monotonic_queue".} =
  if input.isNil or length < 2 or length > csize_t(MaxN + 2): return -1
  let n64 = input[0]
  let window64 = input[1]
  if n64 < 1 or n64 > MaxN or window64 < 1 or window64 > n64 or length != csize_t(n64 + 2): return -1
  let n = int(n64)
  let window = int(window64)
  for i in 0 ..< n:
    if input[2 + i] < int64(low(int32)) or input[2 + i] > int64(high(int32)): return -1
  var deque: array[MaxN, int]
  var head = 0
  var tail = 0
  var hashValue = FnvOffset
  for i in 0 ..< n:
    while head < tail and deque[head] + window <= i: inc head
    while head < tail and input[2 + deque[tail - 1]] <= input[2 + i]: dec tail
    deque[tail] = i
    inc tail
    if i + 1 >= window: hashI32(hashValue, input[2 + deque[head]])
  int64(hashValue and 0x7fff_ffff_ffff_ffff'u64)
