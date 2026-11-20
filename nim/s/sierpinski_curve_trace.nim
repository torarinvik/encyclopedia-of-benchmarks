const MaxOrder = 2
const MaxParseableInput = 2
const MaxStack = 64

type Frame = object
  symbol: uint8
  level: uint8

proc push(stack: var array[MaxStack, Frame], top: var int, symbol, level: uint8) =
  stack[top] = Frame(symbol: symbol, level: level)
  inc top

proc emitCurve(order: uint8, output: ptr UncheckedArray[uint8]): int =
  var stack: array[MaxStack, Frame]
  var top = 0
  var written = 0
  push(stack, top, 5, 0); push(stack, top, 3, order)
  push(stack, top, 7, 0); push(stack, top, 2, order)
  push(stack, top, 9, 0); push(stack, top, 1, order)
  push(stack, top, 11, 0); push(stack, top, 0, order)
  while top > 0:
    dec top
    let frame = stack[top]
    if frame.symbol >= 4:
      output[written] = frame.symbol - 4
      inc written
    elif frame.level > 0:
      let child = frame.level - 1
      case frame.symbol
      of 0:
        push(stack,top,0,child); push(stack,top,5,0); push(stack,top,3,child)
        push(stack,top,12,0); push(stack,top,1,child); push(stack,top,11,0); push(stack,top,0,child)
      of 1:
        push(stack,top,1,child); push(stack,top,11,0); push(stack,top,0,child)
        push(stack,top,18,0); push(stack,top,2,child); push(stack,top,9,0); push(stack,top,1,child)
      of 2:
        push(stack,top,2,child); push(stack,top,9,0); push(stack,top,1,child)
        push(stack,top,16,0); push(stack,top,3,child); push(stack,top,7,0); push(stack,top,2,child)
      else:
        push(stack,top,3,child); push(stack,top,7,0); push(stack,top,2,child)
        push(stack,top,14,0); push(stack,top,0,child); push(stack,top,5,0); push(stack,top,3,child)
  written

proc sierpinski_curve_trace*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "sierpinski_curve_trace".} =
  if input.isNil or length < 1 or length > csize_t(MaxParseableInput): return -1
  if length != 1: return -1
  if input[0] < 0 or input[0] > MaxOrder.int64: return -1
  let order = int(input[0])
  var required = 4
  for _ in 0 ..< order: required *= 4
  if output.isNil or capacity < csize_t(required): return -2
  int64(emitCurve(uint8(order), output))
