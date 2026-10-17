import std/math

proc mutate*(input: ptr UncheckedArray[float64], length: csize_t,
             output: ptr UncheckedArray[float64], capacity: csize_t): int64
             {.cdecl, exportc: "mutate".} =
  if input == nil or length < 2 or length > 130: return -1
  let mu = input[0]
  let countValue = input[1]
  if classify(mu) in {fcNan, fcInf, fcNegInf} or mu < 0.0 or mu > 1.0 or
     classify(countValue) in {fcNan, fcInf, fcNegInf} or floor(countValue) != countValue or countValue < 0.0 or countValue > 64.0: return -1
  let count = int(countValue)
  if int(length) != 2 + 2 * count: return -1
  for index in 0 ..< count:
    let gene = input[2 + index]
    if gene != 0.0 and gene != 1.0: return -1
  for index in 0 ..< count:
    let draw = input[2 + count + index]
    if classify(draw) in {fcNan, fcInf, fcNegInf} or draw < 0.0 or draw >= 1.0: return -1
  if output == nil or capacity < csize_t(count): return -2
  for index in 0 ..< count:
    let gene = input[2 + index]
    let draw = input[2 + count + index]
    output[index] = if draw < mu: 1.0 - gene else: gene
  int64(count)
