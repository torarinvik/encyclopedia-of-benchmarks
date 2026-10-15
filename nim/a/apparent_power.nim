## Selected component of single-phase complex apparent power.
import std/math

proc apparent_power*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "apparent_power".} =
  if values == nil or length != 5: return -1.0e300
  let component = values[0]
  let voltage = values[1]
  let current = values[2]
  let voltageAngle = values[3]
  let currentAngle = values[4]
  if (component != 0 and component != 1) or voltage < 0 or voltage > 1000 or
      current < 0 or current > 1000 or voltageAngle < -360 or voltageAngle > 360 or
      currentAngle < -360 or currentAngle > 360: return -1.0e300
  const pi = 3.14159265358979323846
  let voltageRadians = float64(voltageAngle) * (pi / 180.0)
  let currentRadians = float64(currentAngle) * (pi / 180.0)
  let voltageReal = float64(voltage) * cos(voltageRadians)
  let voltageImag = float64(voltage) * sin(voltageRadians)
  let currentReal = float64(current) * cos(currentRadians)
  let currentImag = float64(current) * sin(currentRadians)
  let real = voltageReal * currentReal - voltageImag * currentImag
  let imag = voltageReal * currentImag + voltageImag * currentReal
  if component == 0: real else: imag
