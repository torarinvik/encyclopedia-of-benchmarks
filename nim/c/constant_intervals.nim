const MaxN = 256

type IntervalState = object
  output: ptr UncheckedArray[uint8]
  count: int
  lastHi: int
  lastValue: int32
  hasLast: bool

proc valueAt(index: int, step, offset, divisor: int64): int32 =
  int32((step * int64(index) + offset) div divisor)

proc storeI32Le(output: ptr UncheckedArray[uint8], position: int, value: int32) =
  let bits = cast[uint32](value)
  for byte in 0 ..< 4:
    output[position + byte] = uint8((bits shr (8 * byte)) and 255'u32)

proc appendInterval(state: var IntervalState, lo, hi: int, value: int32) =
  if state.hasLast and state.lastHi == lo and state.lastValue == value:
    storeI32Le(state.output, (state.count - 1) * 12 + 4, int32(hi))
  else:
    let position = state.count * 12
    storeI32Le(state.output, position, int32(lo))
    storeI32Le(state.output, position + 4, int32(hi))
    storeI32Le(state.output, position + 8, value)
    inc state.count
  state.lastHi = hi
  state.lastValue = value
  state.hasLast = true

proc visitRange(lo, hi: int, step, offset, divisor: int64, state: var IntervalState) =
  let first = valueAt(lo, step, offset, divisor)
  let last = valueAt(hi - 1, step, offset, divisor)
  if first == last or hi - lo == 1:
    appendInterval(state, lo, hi, first)
    return
  let mid = lo + (hi - lo) div 2
  visitRange(lo, mid, step, offset, divisor, state)
  visitRange(mid, hi, step, offset, divisor, state)

proc constant_intervals*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "constant_intervals".} =
  if input == nil or length != 4: return -1
  let nValue = input[0]
  let step = input[1]
  let offset = input[2]
  let divisor = input[3]
  if nValue < 0 or nValue > MaxN or step < 0 or step > 65535
      or offset < 0 or offset > 65535 or divisor < 1 or divisor > 65535: return -1
  let n = int(nValue)
  let maximumBytes = csize_t(n * 12)
  if outputCapacity < maximumBytes or (maximumBytes > 0 and output == nil): return -2
  if n == 0: return 0
  var state = IntervalState(output: output, count: 0, lastHi: 0, lastValue: 0, hasLast: false)
  visitRange(0, n, step, offset, divisor, state)
  int64(state.count)
