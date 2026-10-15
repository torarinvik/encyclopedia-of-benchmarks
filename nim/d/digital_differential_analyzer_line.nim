## Incremental floating-point DDA points encoded as i32 little-endian pairs.
import std/math

type I64Input = ptr UncheckedArray[int64]
type ByteOutput = ptr UncheckedArray[uint8]

proc roundTiesToEven(value: float64): int64 =
  var lower = int64(floor(value))
  let fraction = value - float64(lower)
  if fraction > 0.5 or (fraction == 0.5 and lower mod 2 != 0): inc lower
  lower

proc writeI32Le(output: ByteOutput, position: var csize_t, value: int64) =
  let bits = cast[uint32](int32(value))
  for byte in 0 ..< 4:
    output[position] = uint8((bits shr (byte * 8)) and 255'u32)
    inc position

proc digital_differential_analyzer_line*(values: I64Input, length: csize_t, output: ByteOutput,
                                          outputCapacity: csize_t): int64
    {.cdecl, exportc: "digital_differential_analyzer_line".} =
  if length != 4: return -1
  for index in 0 ..< 4:
    if values[index] < -1_000_000'i64 or values[index] > 1_000_000'i64: return -1
  let dx = values[2] - values[0]
  let dy = values[3] - values[1]
  let steps = max(abs(dx), abs(dy))
  if steps == 0 or steps > 4096: return -1
  let outputBytes = csize_t(steps * 8)
  if outputCapacity < outputBytes or output == nil: return -2
  let xIncrement = float64(dx) / float64(steps)
  let yIncrement = float64(dy) / float64(steps)
  var x = float64(values[0])
  var y = float64(values[1])
  var position = csize_t(0)
  var step = 0'i64
  while step < steps:
    x += xIncrement
    y += yIncrement
    writeI32Le(output, position, roundTiesToEven(x))
    writeI32Le(output, position, roundTiesToEven(y))
    inc step
  int64(outputBytes)
