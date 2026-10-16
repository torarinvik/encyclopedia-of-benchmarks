const InvalidResult = -1.0e300
const CoulombsConstant = 8.9875517923e9
const MaxChargeMicrocoulombs = 1_000_000
const MaxDistanceMillimeters = 1_000_000

proc coulombs_law*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "coulombs_law".} =
  if values.isNil or length != 3: return InvalidResult
  let charge1Value = values[0]
  let charge2Value = values[1]
  let distanceValue = values[2]
  if charge1Value == 0 or charge2Value == 0 or
      charge1Value < -MaxChargeMicrocoulombs or charge1Value > MaxChargeMicrocoulombs or
      charge2Value < -MaxChargeMicrocoulombs or charge2Value > MaxChargeMicrocoulombs or
      distanceValue < 1 or distanceValue > MaxDistanceMillimeters: return InvalidResult

  let charge1 = float64(charge1Value) / 1_000_000.0
  let charge2 = float64(charge2Value) / 1_000_000.0
  let distance = float64(distanceValue) / 1_000.0
  var chargeProduct = charge1 * charge2
  if chargeProduct < 0.0: chargeProduct = -chargeProduct
  CoulombsConstant * chargeProduct / (distance * distance)
