const MaxLength = 8192
const OutputBytes = 9
const Modulus = 139968'i64
const Multiplier = 3877'i64
const Increment = 29573'i64

proc sourceHeapsort(n: int, values: var array[MaxLength + 1, float64]) =
  var ir = n
  var l = (n div 2) + 1
  while true:
    var rra: float64
    if l > 1:
      dec l
      rra = values[l]
    else:
      rra = values[ir]
      values[ir] = values[1]
      dec ir
      if ir == 1:
        values[1] = rra
        return
    var i = l
    var j = l * 2
    while j <= ir:
      if j < ir and values[j] < values[j + 1]: inc j
      if rra < values[j]:
        values[i] = values[j]
        i = j
        j += i
      else:
        j = ir + 1
    values[i] = rra

proc writeFixedSix(value: float64, output: ptr UncheckedArray[uint8]) =
  let millionths = uint32(value * 1_000_000.0 + 0.5)
  let whole = millionths div 1_000_000'u32
  var fraction = millionths mod 1_000_000'u32
  output[0] = uint8(48 + whole)
  output[1] = uint8(ord('.'))
  var divisor = 100_000'u32
  for index in 2 ..< 8:
    output[index] = uint8(48 + (fraction div divisor) mod 10'u32)
    divisor = divisor div 10'u32
  output[8] = uint8(ord('\n'))

proc shootout_heapsort*(length: int64, output: ptr UncheckedArray[uint8],
                        outputCapacity: csize_t): int64
    {.cdecl, exportc: "shootout_heapsort".} =
  if length < 2 or length > MaxLength: return -1
  if output.isNil or outputCapacity < csize_t(OutputBytes): return -2

  var values: array[MaxLength + 1, float64]
  var state = 42'i64
  for index in 1 .. int(length):
    state = (state * Multiplier + Increment) mod Modulus
    values[index] = 1.0 * float64(state) / float64(Modulus)
  sourceHeapsort(int(length), values)
  writeFixedSix(values[int(length)], output)
  OutputBytes.int64
