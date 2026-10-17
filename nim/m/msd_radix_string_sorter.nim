const
  MaxStrings = 256
  MaxLength = 32
  MaxInput = 1 + MaxStrings * (1 + MaxLength) + 1
  FnvOffset = 14695981039346656037'u64
  FnvPrime = 1099511628211'u64
  Mask63 = 0x7fff_ffff_ffff_ffff'u64

type EncodedString = object
  bytes: array[MaxLength, uint8]
  length: int

proc bucket(value: EncodedString, digit: int): int =
  if digit >= value.length: 0 else: int(value.bytes[digit]) + 1

proc msdSort(values, auxiliary: var array[MaxStrings, EncodedString], low, high, digit: int) =
  if high - low < 2 or digit >= MaxLength: return
  var counts: array[257, int]
  for i in low ..< high: inc counts[bucket(values[i], digit)]
  var starts, next: array[257, int]
  var position = low
  for b in 0 ..< 257:
    starts[b] = position
    next[b] = position
    position += counts[b]
  for i in low ..< high:
    let b = bucket(values[i], digit)
    auxiliary[next[b]] = values[i]
    inc next[b]
  for i in low ..< high: values[i] = auxiliary[i]
  for b in 1 ..< 257:
    let first = starts[b]
    let last = first + counts[b]
    if last - first > 1: msdSort(values, auxiliary, first, last, digit + 1)

proc msd_radix_string_sorter*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "msd_radix_string_sorter".} =
  if input.isNil or length == 0 or length > csize_t(MaxInput): return -1
  if input[0] < 0 or input[0] > MaxStrings: return -1
  let count = int(input[0])
  var values, auxiliary: array[MaxStrings, EncodedString]
  var position = 1
  for i in 0 ..< count:
    if position >= int(length) or input[position] < 0 or input[position] > MaxLength: return -1
    let n = int(input[position]); inc position
    if n > int(length) - position: return -1
    values[i].length = n
    for digit in 0 ..< n:
      if input[position] < 0 or input[position] > 255: return -1
      values[i].bytes[digit] = uint8(input[position])
      inc position
  if position != int(length): return -1
  if count > 1: msdSort(values, auxiliary, 0, count, 0)
  var hash = FnvOffset
  hash = (hash xor uint64(count and 255)) *% FnvPrime
  hash = (hash xor uint64((count shr 8) and 255)) *% FnvPrime
  for i in 0 ..< count:
    hash = (hash xor uint64(values[i].length)) *% FnvPrime
    for digit in 0 ..< values[i].length:
      hash = (hash xor uint64(values[i].bytes[digit])) *% FnvPrime
  int64(hash and Mask63)
