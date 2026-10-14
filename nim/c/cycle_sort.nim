## In-place cycle sort; equal values are skipped when locating each rank.
proc cycle_sort*(values: ptr UncheckedArray[int64], length: csize_t) {.cdecl, exportc: "cycle_sort".} =
  if length < 2:
    return
  var cycleStart = csize_t(0)
  while cycleStart < length - 1:
    var item = values[cycleStart]
    var position = cycleStart
    for scan in (cycleStart + 1) ..< length:
      if values[scan] < item:
        inc position
    if position != cycleStart:
      while position < length and item == values[position]:
        inc position
      if position < length:
        var temporary = values[position]
        values[position] = item
        item = temporary
        while position != cycleStart:
          position = cycleStart
          for scan in (cycleStart + 1) ..< length:
            if values[scan] < item:
              inc position
          while position < length and item == values[position]:
            inc position
          if position == length:
            break
          temporary = values[position]
          values[position] = item
          item = temporary
    inc cycleStart
