proc space_saving_frequent_items*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "space_saving_frequent_items".} =
  if input.isNil or length < 2 or length > 67: return -1
  let kr = input[0]
  let nr = input[1]
  if kr < 1 or kr > 8 or nr < 0 or nr > 64: return -1
  let k = int(kr)
  let n = int(nr)
  if length != csize_t(2+n): return -1
  for i in 0 ..< n:
    if input[2+i] < -1000 or input[2+i] > 1000: return -1
  var items, estimates, errors: array[8, int64]
  var used = 0
  for i in 0 ..< n:
    let item = input[2+i]
    var found = -1
    for j in 0 ..< used:
      if items[j] == item:
        found = j
        break
    if found >= 0:
      estimates[found] += 1
    elif used < k:
      items[used] = item
      estimates[used] = 1
      errors[used] = 0
      used += 1
    else:
      var victim = 0
      for j in 1 ..< used:
        if estimates[j] < estimates[victim] or
            (estimates[j] == estimates[victim] and items[j] < items[victim]):
          victim = j
      let minimum = estimates[victim]
      items[victim] = item
      estimates[victim] = minimum + 1
      errors[victim] = minimum
  var sortIndex = 1
  while sortIndex < used:
    var j = sortIndex
    while j > 0 and items[j] < items[j-1]:
      swap(items[j], items[j-1])
      swap(estimates[j], estimates[j-1])
      swap(errors[j], errors[j-1])
      dec j
    inc sortIndex
  let bytes = 8 * (1 + 3 * used)
  if output.isNil or capacity < csize_t(bytes): return -2
  var fields: array[25, int64]
  fields[0] = int64(used)
  for i in 0 ..< used:
    fields[1+3*i] = items[i]
    fields[2+3*i] = estimates[i]
    fields[3+3*i] = errors[i]
  var staged: array[200, uint8]
  for i in 0 ..< 1+3*used:
    let bits = cast[uint64](fields[i])
    for b in 0 ..< 8: staged[8*i+b] = uint8((bits shr (8*b)) and 255)
  for i in 0 ..< bytes: output[i] = staged[i]
  int64(bytes)
