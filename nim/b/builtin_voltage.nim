## PN junction built-in voltage over bounded integer concentrations.
import std/math

proc builtin_voltage*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "builtin_voltage".} =
  if values == nil or length != 3: return -1.0e300
  let donor = values[0]
  let acceptor = values[1]
  let intrinsic = values[2]
  if donor < 1 or donor > 1000 or acceptor < 1 or acceptor > 1000 or intrinsic < 1 or intrinsic > 1000 or donor <= intrinsic or acceptor <= intrinsic:
    return -1.0e300
  const boltzmann = 1.380649e-23
  const electronVolt = 1.602176634e-19
  let ratio = (float64(donor) * float64(acceptor)) / (float64(intrinsic) * float64(intrinsic))
  boltzmann * 300.0 * ln(ratio) / electronVolt
