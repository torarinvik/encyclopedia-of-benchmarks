const MaxInputLength = 64
const MaxErrors = 60

proc pid*(input: ptr UncheckedArray[float64], length: csize_t,
          output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "pid".} =
  if input == nil or length < 5 or length > csize_t(MaxInputLength): return -1
  let errorCount = int(length) - 4
  let kp64 = input[0]
  let ki64 = input[1]
  let kd64 = input[2]
  let dt64 = input[3]
  if kp64 != kp64 or kp64 < -1.0 or kp64 > 1.0 or
     ki64 != ki64 or ki64 < -1.0 or ki64 > 1.0 or
     kd64 != kd64 or kd64 < -1.0 or kd64 > 1.0 or
     dt64 != dt64 or (dt64 != 0.0 and (dt64 < 0.01 or dt64 > 1.0)) or
     errorCount < 1 or errorCount > MaxErrors:
    return -1
  var errors: array[MaxErrors, float32]
  for index in 0 ..< errorCount:
    let value = input[index + 4]
    if value != value or value < -1.0 or value > 1.0: return -1
    errors[index] = float32(value)
  if output == nil or outputCapacity < csize_t(errorCount): return -2

  let kp = float32(kp64)
  let ki = float32(ki64)
  let kd = float32(kd64)
  let dt = float32(dt64)
  var integral = 0.0'f32
  var lastError = 0.0'f32
  for index in 0 ..< errorCount:
    let error = errors[index]
    let proportional = error * kp
    var integralStep = error * dt
    integralStep = integralStep * ki
    integral = integral + integralStep
    var derivative = 0.0'f32
    if dt != 0.0'f32:
      let difference = error - lastError
      let rate = difference / dt
      derivative = rate * kd
    lastError = error
    let partial = proportional + integral
    let result = partial + derivative
    output[index] = float64(result)
  int64(errorCount)
