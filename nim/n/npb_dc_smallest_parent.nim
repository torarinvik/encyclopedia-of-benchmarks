## Bounded clean-room NASA NPB DC smallest-parent profile; see NAS-03-005.

const MaxDims = 5
const MaxRows = 16
const MaxMasks = 32

proc countBits(value: int): int =
  var bits = value
  while bits != 0:
    result += (bits and 1)
    bits = bits shr 1

proc npb_dc_smallest_parent*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "npb_dc_smallest_parent".} =
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

  var keys: array[MaxMasks, array[MaxRows, array[MaxDims, int64]]]
  var sums: array[MaxMasks, array[MaxRows, int64]]
  var counts: array[MaxMasks, int]
  var parents: array[MaxMasks, int]
  for mask in 0 ..< MaxMasks: parents[mask] = -2
  let full = (1 shl dimensions) - 1
  parents[full] = -1
  for row in 0 ..< rows:
    var group = 0
    while group < counts[full]:
      var equal = true
      for dimension in 0 ..< dimensions:
        if (full and (1 shl dimension)) != 0 and keys[full][group][dimension] != attributes[row][dimension]: equal = false
      if equal: break
      inc group
    if group == counts[full]:
      for dimension in 0 ..< dimensions: keys[full][group][dimension] = attributes[row][dimension]
      sums[full][group] = measures[row]
      inc counts[full]
    else:
      sums[full][group] += measures[row]
  for index in 1 ..< counts[full]:
    var position = index
    while position > 0:
      var less = false
      for dimension in 0 ..< dimensions:
        if keys[full][position][dimension] < keys[full][position - 1][dimension]: less = true; break
        if keys[full][position][dimension] > keys[full][position - 1][dimension]: break
      if not less: break
      swap(keys[full][position], keys[full][position - 1])
      swap(sums[full][position], sums[full][position - 1])
      dec position

  for wanted in countdown(dimensions - 1, 0):
    for mask in 0 .. full:
      if countBits(mask) != wanted: continue
      var parent = -1
      var best = MaxRows + 1
      for dimension in 0 ..< dimensions:
        let bit = 1 shl dimension
        if (mask and bit) != 0: continue
        let candidate = mask or bit
        if parent < 0 or counts[candidate] < best:
          parent = candidate
          best = counts[candidate]
      if parent < 0: return -1
      parents[mask] = parent
      for parentGroup in 0 ..< counts[parent]:
        var group = 0
        while group < counts[mask]:
          var equal = true
          for dimension in 0 ..< dimensions:
            if (mask and (1 shl dimension)) != 0 and keys[mask][group][dimension] != keys[parent][parentGroup][dimension]: equal = false
          if equal: break
          inc group
        if group == counts[mask]:
          for dimension in 0 ..< dimensions:
            if (mask and (1 shl dimension)) != 0: keys[mask][group][dimension] = keys[parent][parentGroup][dimension]
          sums[mask][group] = sums[parent][parentGroup]
          inc counts[mask]
        else:
          sums[mask][group] += sums[parent][parentGroup]
      for index in 1 ..< counts[mask]:
        var position = index
        while position > 0:
          var less = false
          for dimension in 0 ..< dimensions:
            if (mask and (1 shl dimension)) == 0: continue
            if keys[mask][position][dimension] < keys[mask][position - 1][dimension]: less = true; break
            if keys[mask][position][dimension] > keys[mask][position - 1][dimension]: break
          if not less: break
          swap(keys[mask][position], keys[mask][position - 1])
          swap(sums[mask][position], sums[mask][position - 1])
          dec position

  var checksum = 0'i64
  for mask in 0 .. full:
    let view = int64(mask + 1)
    checksum += view * 1_000_000 + (int64(parents[mask]) + 2) * 10_000 + int64(counts[mask]) * 1_000
    for group in 0 ..< counts[mask]:
      let rank = int64(group + 1)
      checksum += rank * (sums[mask][group] + 1)
      for dimension in 0 ..< dimensions:
        if (mask and (1 shl dimension)) != 0:
          checksum += rank * int64(dimension + 1) * (keys[mask][group][dimension] + 1)
  checksum
