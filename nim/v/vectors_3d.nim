import std/math

const ComponentLimit = 1_000_000.0
const Epsilon = 1.0e-9

proc dotProduct(ax, ay, az, bx, by, bz: float32): float32 =
  result = ax * bx
  result += ay * by
  result += az * bz

proc vectorNorm(x, y, z: float32): float32 =
  float32(sqrt(float64(dotProduct(x, y, z, x, y, z))))

proc vectors_3d*(input: ptr UncheckedArray[float64], inputLen: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "vectors_3d".} =
  if input.isNil or inputLen == 0: return -1
  let operationValue = input[0]
  if operationValue != operationValue or operationValue < 0.0 or
      operationValue > 7.0 or floor(operationValue) != operationValue: return -1
  let operation = int(operationValue)
  let requiredLength = if operation <= 3 or operation == 7: 7 else: 4
  if inputLen != csize_t(requiredLength): return -1

  var components: array[6, float32]
  let componentCount = requiredLength - 1
  for index in 0 ..< componentCount:
    let value = input[index + 1]
    if value != value or abs(value) > ComponentLimit: return -1
    components[index] = float32(value)
  let ax = components[0]
  let ay = components[1]
  let az = components[2]
  let bx = components[3]
  let by = components[4]
  let bz = components[5]

  var result: array[9, float64]
  var resultLength: int
  case operation
  of 0:
    resultLength = 3
    result[0] = float64(ax + bx); result[1] = float64(ay + by); result[2] = float64(az + bz)
  of 1:
    resultLength = 3
    result[0] = float64(ax - bx); result[1] = float64(ay - by); result[2] = float64(az - bz)
  of 2:
    resultLength = 1
    result[0] = float64(dotProduct(ax, ay, az, bx, by, bz))
  of 3:
    resultLength = 3
    result[0] = float64(ay * bz - az * by)
    result[1] = float64(-ax * bz + az * bx)
    result[2] = float64(ax * by - ay * bx)
  of 4:
    resultLength = 1
    result[0] = float64(vectorNorm(ax, ay, az))
  of 5:
    resultLength = 3
    let norm = vectorNorm(ax, ay, az)
    if float64(norm) >= Epsilon and norm != 1.0'f32:
      result[0] = float64(ax / norm); result[1] = float64(ay / norm); result[2] = float64(az / norm)
  of 6:
    resultLength = 9
    result = [0.0, float64(-az), float64(ay), float64(az), 0.0, float64(-ax),
              float64(-ay), float64(ax), 0.0]
  of 7:
    resultLength = 1
    let normA = vectorNorm(ax, ay, az)
    let normB = vectorNorm(bx, by, bz)
    if float64(normA) < Epsilon or float64(normB) < Epsilon:
      result[0] = arccos(2.0)
    else:
      let cosine = dotProduct(ax, ay, az, bx, by, bz) / (normA * normB)
      result[0] = arccos(float64(cosine))
  else:
    return -1

  if output.isNil or outputCapacity < csize_t(resultLength): return -2
  for index in 0 ..< resultLength: output[index] = result[index]
  int64(resultLength)
