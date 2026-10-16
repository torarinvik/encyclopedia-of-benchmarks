proc reversort*(values: ptr UncheckedArray[int64], length: csize_t)
    {.cdecl, exportc: "reversort".} =
  if length < 2: return
  for index in 0 ..< int(length - 1):
    var minimum = index
    for probe in index + 1 ..< int(length):
      if values[probe] < values[minimum]: minimum = probe
    var left = index
    var right = minimum
    while left < right:
      let temporary = values[left]
      values[left] = values[right]
      values[right] = temporary
      inc left
      dec right
