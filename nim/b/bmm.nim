# Modified bounded-profile derivative; carry benchmarks/b/bmm/LICENSE with this source.

const MaxSize = 128
const SourceSize = 1024
const MaxCells = MaxSize * MaxSize
const MaxOutputBytes = 29

type Matrix = array[MaxCells, float32]
type OutputBuffer = array[MaxOutputBytes, uint8]

proc nextRandom(state: var uint32): uint32 =
  state = uint32((uint64(state) * 1_664_525'u64 + 1_013_904_223'u64) and 0xffff_ffff'u64)
  (state shr 16) and 0x7fff'u32

proc appendUnsigned(valueInput: uint32, staged: var OutputBuffer, used: var int) =
  var value = valueInput
  var reverse: array[10, uint8]
  var count = 0
  while true:
    reverse[count] = uint8(ord('0') + int(value mod 10'u32))
    inc count
    value = value div 10'u32
    if value == 0: break
  while count > 0:
    dec count
    staged[used] = reverse[count]
    inc used

proc versabenchBmmImpl(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 =
  if input == nil or inputLength != 2: return -1
  let sizeValue = input[0]
  let blockValue = input[1]
  if sizeValue < 1 or sizeValue > MaxSize or blockValue < 1 or
      blockValue > sizeValue or sizeValue mod blockValue != 0: return -1
  let size = int(sizeValue)
  let block = int(blockValue)

  var a, b, c: Matrix
  var seed = 1'u32
  for i in 0 ..< size:
    for j in 0 ..< SourceSize:
      let randomA = nextRandom(seed)
      let randomB = nextRandom(seed)
      if j < size:
        let shiftA = ((j and 31) + 32 - (i and 31)) and 31
        let shiftB = (i + j) and 31
        a[i * size + j] = float32((randomA shr shiftA) and 15'u32)
        b[i * size + j] = float32((randomB shl shiftB) and 15'u32)

  for outerI in countup(0, size - 1, block):
    for outerJ in countup(0, size - 1, block):
      for outerK in countup(0, size - 1, block):
        for i in outerI ..< outerI + block:
          for j in outerJ ..< outerJ + block:
            let cell = i * size + j
            for k in outerK ..< outerK + block:
              c[cell] = c[cell] + a[i * size + k] * b[k * size + j]

  var total = 0.0'f32
  for outerI in countup(0, size - 1, block):
    for outerJ in countup(0, size - 1, block):
      var subtotal = 0.0'f32
      for i in outerI ..< outerI + block:
        for j in outerJ ..< outerJ + block:
          subtotal = subtotal + c[i * size + j]
      total = total + subtotal

  var staged: OutputBuffer
  var used = 0
  for ch in "final sum = ":
    staged[used] = uint8(ord(ch))
    inc used
  appendUnsigned(uint32(total), staged, used)
  for ch in ".000000\n":
    staged[used] = uint8(ord(ch))
    inc used
  if output == nil or capacity < csize_t(used): return -2
  for i in 0 ..< used: output[csize_t(i)] = staged[i]
  int64(used)

proc versabench_bmm*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "versabench_bmm".} =
  versabenchBmmImpl(input, inputLength, output, capacity)
