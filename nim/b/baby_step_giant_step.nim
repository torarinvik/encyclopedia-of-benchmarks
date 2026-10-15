## Packed input [a, b, n]; return the least positive discrete logarithm or -1.
const TableSize = 65_536
const TableMask = TableSize - 1
const MaxModulus = 1_000_000_007'u64

proc gcdU64(left, right: uint64): uint64 =
  var a = left
  var b = right
  while b != 0:
    let remainder = a mod b
    a = b
    b = remainder
  a

proc ceilSqrt(value: uint64): int =
  var low = 1'u64
  var high = 31_624'u64
  while low < high:
    let middle = low + (high - low) div 2
    if middle * middle >= value: high = middle else: low = middle + 1
  int(low)

proc insertBaby(keys: var seq[uint64], encodedSteps: var seq[uint32], key: uint64, step: uint32) =
  var slot = int(key and uint64(TableMask))
  while encodedSteps[slot] != 0 and keys[slot] != key:
    slot = (slot + 1) and TableMask
  keys[slot] = key
  encodedSteps[slot] = step + 1

proc findBaby(keys: seq[uint64], encodedSteps: seq[uint32], key: uint64): int =
  var slot = int(key and uint64(TableMask))
  while encodedSteps[slot] != 0:
    if keys[slot] == key: return int(encodedSteps[slot] - 1)
    slot = (slot + 1) and TableMask
  -1

proc baby_step_giant_step*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "baby_step_giant_step".} =
  if length != 3: return -1
  let aInput = values[0]
  let bInput = values[1]
  let nInput = values[2]
  if aInput < 0 or bInput < 0 or nInput < 1 or nInput > int64(MaxModulus) or
      aInput >= nInput or bInput >= nInput: return -1
  let a = uint64(aInput)
  let b = uint64(bInput)
  let modulus = uint64(nInput)
  if gcdU64(a, modulus) != 1: return -1

  let m = ceilSqrt(modulus)
  var keys = newSeq[uint64](TableSize)
  var encodedSteps = newSeq[uint32](TableSize)
  var step = 1'u64
  for index in 0 ..< m:
    insertBaby(keys, encodedSteps, (step * b) mod modulus, uint32(index))
    step = (step * a) mod modulus
  let giantStep = step
  var index = m
  while uint64(index) <= modulus:
    let babyIndex = findBaby(keys, encodedSteps, step)
    if babyIndex >= 0: return int64(index - babyIndex)
    step = (step * giantStep) mod modulus
    index += m
  -1
