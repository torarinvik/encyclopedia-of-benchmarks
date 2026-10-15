## Sum an inclusive arithmetic progression from packed [from, to, step].
proc arithmetic_progression*(values: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "arithmetic_progression".} =
  if values == nil or length != 3: return -1
  let fromValue = values[0]
  let toValue = values[1]
  let step = values[2]
  if fromValue < -1000000 or fromValue > 1000000 or toValue < -1000000 or toValue > 1000000:
    return -1
  if step < -1000000 or step > 1000000 or step == 0: return -1
  if (fromValue < toValue and step < 0) or (fromValue > toValue and step > 0): return -1
  let count = (toValue - fromValue) div step
  let last = fromValue + count * step
  return ((count + 1) * (fromValue + last)) div 2
