## Minimum time to cross two assembly lines using station-by-station dynamic programming.
proc assembly_line_scheduling*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "assembly_line_scheduling".} =
  if values == nil or length < 7 or values[0] < 1 or values[0] > 64: return -1
  let n = int(values[0])
  if int(length) != 4 * n + 3: return -1
  for index in 0 ..< int(length):
    if values[index] < 0 or values[index] > 1000: return -1

  let a0 = 1
  let a1 = a0 + n
  let t0 = a1 + n
  let t1 = t0 + n - 1
  let entry = t1 + n - 1
  var line0 = values[entry] + values[a0]
  var line1 = values[entry + 1] + values[a1]
  for station in 1 ..< n:
    let stay0 = line0 + values[a0 + station]
    let switch0 = line1 + values[t1 + station - 1] + values[a0 + station]
    let stay1 = line1 + values[a1 + station]
    let switch1 = line0 + values[t0 + station - 1] + values[a1 + station]
    line0 = min(stay0, switch0)
    line1 = min(stay1, switch1)
  let total0 = line0 + values[entry + 2]
  let total1 = line1 + values[entry + 3]
  let answer = min(total0, total1)
  if output == nil or outputCapacity < 4: return -2
  for byte in 0 ..< 4:
    output[byte] = uint8((answer shr (8 * byte)) and 255)
  4
