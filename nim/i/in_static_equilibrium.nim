const InvalidResult = -1'i64

proc in_static_equilibrium*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "in_static_equilibrium".} =
  if values == nil or length < 5: return InvalidResult
  let nValue = values[0]
  if nValue < 1 or nValue > 100 or length != 1 + 4 * csize_t(nValue): return InvalidResult
  let n = int(nValue)
  var totalMoment = 0'i64
  for i in 0 ..< n:
    let fx = values[1 + i]
    let fy = values[1 + n + i]
    let lx = values[1 + 2 * n + i]
    let ly = values[1 + 3 * n + i]
    if fx < -1000 or fx > 1000 or fy < -1000 or fy > 1000 or lx < -1000 or lx > 1000 or ly < -1000 or ly > 1000: return InvalidResult
    totalMoment += lx * fy - ly * fx
  if totalMoment == 0: 1 else: 0
