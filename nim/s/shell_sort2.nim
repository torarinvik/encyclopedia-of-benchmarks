## Shell sort using the Ciura gap sequence.
const CiuraGaps = [701, 301, 132, 57, 23, 10, 4, 1]

proc shell_sort2*(values: ptr UncheckedArray[int64], length: csize_t)
    {.cdecl, exportc: "shell_sort2".} =
  let n = int(length)
  for gapValue in CiuraGaps:
    let gap = int(gapValue)
    for index in gap ..< n:
      let key = values[index]
      var position = index
      while position >= gap and values[position - gap] > key:
        values[position] = values[position - gap]
        position -= gap
      values[position] = key
