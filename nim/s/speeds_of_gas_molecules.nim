import math

const MaxInputLength = 4
const MaxTemperatureMk = 1_000_000'i64
const MaxMolarMassMicro = 1_000_000_000'i64
const GasConstant = 8.31446261815324
const PiValue = 3.14159265358979323846264338327950288
const InvalidResult = -1.0e300

proc speeds_of_gas_molecules*(input: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "speeds_of_gas_molecules".} =
  if input == nil or length < 3 or length > csize_t(MaxInputLength): return InvalidResult
  let operation = input[0]
  let temperatureMk = input[1]
  let molarMassMicro = input[2]
  if length != 3 or operation < 0 or operation > 1 or
      temperatureMk < 0 or temperatureMk > MaxTemperatureMk or
      molarMassMicro < 1 or molarMassMicro > MaxMolarMassMicro: return InvalidResult

  let temperature = float64(temperatureMk) / 1000.0
  let molarMass = float64(molarMassMicro) / 1_000_000.0
  if operation == 0:
    return pow((8.0 * GasConstant * temperature) / (PiValue * molarMass), 0.5)
  pow((2.0 * GasConstant * temperature) / molarMass, 0.5)
