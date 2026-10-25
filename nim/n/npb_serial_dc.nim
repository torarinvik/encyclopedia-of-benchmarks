## NAS Parallel Benchmarks 3.3 DC source notice:
## Permission to use, copy, distribute and modify this software for any purpose
## with or without fee is hereby granted. We request, however, that all derived
## work reference the NAS Parallel Benchmarks 3.3. This software is provided
## "as is" without express or implied warranty.
##
## Clean-room bounded adaptation: packed input and ordered scalar checksum
## replace generated files and the original memory management harness.

const MaxDims = 5
const MaxRows = 16

proc npb_serial_dc*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "npb_serial_dc".} =
  if input.isNil or length < 4 or length > 98: return -1
  if input[0] < 1 or input[0] > MaxDims or input[1] < 1 or input[1] > MaxRows: return -1
  let dimensions = int(input[0])
  let rows = int(input[1])
  if int(length) != 2 + rows * (dimensions + 1): return -1

  var attributes: array[MaxRows, array[MaxDims, int64]]
  var measures: array[MaxRows, int64]
  var offset = 2
  for row in 0 ..< rows:
    for dimension in 0 ..< dimensions:
      let value = input[offset]
      inc offset
      if value < 0 or value > 7: return -1
      attributes[row][dimension] = value
    measures[row] = input[offset]
    inc offset
    if measures[row] < 0 or measures[row] > 1000: return -1

  var checksum = 0'i64
  for mask in 1 ..< (1 shl dimensions):
    var keys: array[MaxRows, array[MaxDims, int64]]
    var sums: array[MaxRows, int64]
    var groupCount = 0
    for row in 0 ..< rows:
      var group = 0
      while group < groupCount:
        var equal = true
        for dimension in 0 ..< dimensions:
          if (mask and (1 shl dimension)) != 0 and keys[group][dimension] != attributes[row][dimension]: equal = false
        if equal: break
        inc group
      if group == groupCount:
        for dimension in 0 ..< dimensions:
          if (mask and (1 shl dimension)) != 0: keys[group][dimension] = attributes[row][dimension]
        sums[group] = measures[row]
        inc groupCount
      else:
        sums[group] += measures[row]

    for index in 1 ..< groupCount:
      var position = index
      while position > 0:
        var comparison = 0
        for dimension in 0 ..< dimensions:
          if (mask and (1 shl dimension)) == 0: continue
          if keys[position][dimension] < keys[position - 1][dimension]:
            comparison = -1
            break
          if keys[position][dimension] > keys[position - 1][dimension]:
            comparison = 1
            break
        if comparison >= 0: break
        for dimension in 0 ..< dimensions: swap(keys[position][dimension], keys[position - 1][dimension])
        swap(sums[position], sums[position - 1])
        dec position

    let view = int64(mask)
    checksum += view * 1009 + int64(groupCount) * 9176
    for group in 0 ..< groupCount:
      checksum += (view + 1) * int64(group + 1) * (sums[group] + 13)
      for dimension in 0 ..< dimensions:
        if (mask and (1 shl dimension)) != 0:
          checksum += int64(dimension + 1) * (keys[group][dimension] + 1) * int64(group + 3) * (view + 5)
  checksum
