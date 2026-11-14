proc exponential_histogram_window*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "exponential_histogram_window".} =
  if input == nil or length < 2 or length > 130 or input[0] < 1 or input[0] > 64 or input[1] < 0 or input[1] > 128: return -1
  let window = int(input[0])
  let n = int(input[1])
  if int(length) != 2+n: return -1
  for i in 0 ..< n:
    if input[2+i] != 0 and input[2+i] != 1: return -1
  if output == nil or capacity < csize_t(8*n): return -2
  var ends, sizes: array[128, int]
  var used = 0
  for time in 0 ..< n:
    while used != 0 and time >= window and ends[0] <= time-window:
      for j in 1 ..< used:
        ends[j-1] = ends[j]
        sizes[j-1] = sizes[j]
      dec used
    if input[2+time] == 1:
      ends[used] = time
      sizes[used] = 1
      inc used
    var size = 1
    while size <= 128:
      var first = used
      var second = used
      var found = 0
      for j in 0 ..< used:
        if sizes[j] == size:
          if found == 0: first = j
          elif found == 1: second = j
          inc found
      if found > 2:
        sizes[second] = 2*size
        for j in first+1 ..< used:
          ends[j-1] = ends[j]
          sizes[j-1] = sizes[j]
        dec used
      size *= 2
    var total = 0
    for j in 0 ..< used: total += sizes[j]
    let oldest = if used == 0: 0 else: sizes[0]
    var bits = uint64(2*total-oldest)
    for j in 0 ..< 8:
      output[8*time+j] = uint8(bits and 255'u64)
      bits = bits shr 8
  int64(8*n)
