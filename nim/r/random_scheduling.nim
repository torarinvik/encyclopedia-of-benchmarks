const
  MaxTaskCount = 32
  MaxInputLength = 35
  MaxOutputBytes = 256
  JavaMultiplier = 0x5deece66d'u64
  JavaAddend = 0xb'u64
  JavaMask = 0xffffffffffff'u64

type JavaRandom = object
  state: uint64

proc nextBits(random: var JavaRandom, bits: int): uint32 =
  random.state = (random.state * JavaMultiplier + JavaAddend) and JavaMask
  uint32(random.state shr (48 - bits))

proc nextInt(random: var JavaRandom, bound: uint32): uint32 =
  if (bound and (bound - 1)) == 0:
    return uint32((uint64(bound) * uint64(nextBits(random, 31))) shr 31)
  while true:
    let bits = nextBits(random, 31)
    let value = bits mod bound
    if uint64(bits) - uint64(value) + uint64(bound - 1) <= uint64(high(int32)):
      return value

proc putI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xff'u64)

proc randomScheduling*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "random_scheduling".} =
  if input == nil or inputLength < 2 or inputLength > MaxInputLength.csize_t: return -1
  if input[1] < 0 or input[1] > MaxTaskCount.int64: return -1
  let count = int(input[1])
  if inputLength != csize_t(count + 2): return -1
  var tasks: array[MaxTaskCount, int64]
  for index in 0 ..< count:
    let task = input[index + 2]
    if task < int64(low(int32)) or task > int64(high(int32)): return -1
    tasks[index] = task

  var random = JavaRandom(state: (cast[uint64](input[0]) xor JavaMultiplier) and JavaMask)
  for size in countdown(count, 2):
    let selected = int(nextInt(random, uint32(size)))
    swap(tasks[size - 1], tasks[selected])

  let outputBytes = count * 8
  if outputBytes > MaxOutputBytes: return -1
  if output == nil or capacity < csize_t(outputBytes): return -2
  for index in 0 ..< count: putI64Le(output, index * 8, tasks[index])
  int64(outputBytes)
