import std/math

proc siExponent(code: float64): int =
  if code == 0.0: return 24
  if code == 1.0: return 21
  if code == 2.0: return 18
  if code == 3.0: return 15
  if code == 4.0: return 12
  if code == 5.0: return 9
  if code == 6.0: return 6
  if code == 7.0: return 3
  if code == 8.0: return 2
  if code == 9.0: return 1
  if code == 10.0: return -1
  if code == 11.0: return -2
  if code == 12.0: return -3
  if code == 13.0: return -6
  if code == 14.0: return -9
  if code == 15.0: return -12
  if code == 16.0: return -15
  if code == 17.0: return -18
  if code == 18.0: return -21
  if code == 19.0: return -24
  1000

proc binaryExponent(code: float64): int =
  if code == 20.0: return 8
  if code == 21.0: return 7
  if code == 22.0: return 6
  if code == 23.0: return 5
  if code == 24.0: return 4
  if code == 25.0: return 3
  if code == 26.0: return 2
  if code == 27.0: return 1
  1000

proc prefix_conversions*(knownAmount, knownCode, unknownCode: float64): float64
    {.cdecl, exportc: "prefix_conversions".} =
  if knownAmount != knownAmount or knownAmount < -1_000_000.0 or knownAmount > 1_000_000.0:
    return -1e300
  let knownSi = siExponent(knownCode)
  let unknownSi = siExponent(unknownCode)
  if knownSi != 1000 and unknownSi != 1000:
    return knownAmount * pow(10.0, float64(knownSi - unknownSi))
  let knownBinary = binaryExponent(knownCode)
  let unknownBinary = binaryExponent(unknownCode)
  if knownBinary != 1000 and unknownBinary != 1000:
    return knownAmount * pow(2.0, float64((knownBinary - unknownBinary) * 10))
  -1e300
