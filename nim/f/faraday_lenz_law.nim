proc faraday_lenz_law*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "faraday_lenz_law".} =
  if values.isNil or length != 3: return low(int64)
  let finalFlux = values[0]
  let initialFlux = values[1]
  let interval = values[2]
  if (finalFlux < -1_000_000_000 or finalFlux > 1_000_000_000 or
      initialFlux < -1_000_000_000 or initialFlux > 1_000_000_000 or
      interval < 1 or interval > 1_000_000_000): return low(int64)
  let numerator = -(finalFlux - initialFlux) * 10
  let magnitude = abs(numerator)
  var quotient = magnitude div interval
  let remainder = magnitude mod interval
  if 2 * remainder > interval or (2 * remainder == interval and quotient mod 2 != 0):
    inc quotient
  if numerator < 0: -quotient else: quotient
