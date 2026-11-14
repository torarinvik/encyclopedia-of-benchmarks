## Unverified deterministic planted 3-SAT generator draft.
proc planted_3sat_clause_generator*(input: ptr UncheckedArray[int64], length: csize_t,
                                   output: ptr UncheckedArray[uint8], capacity: csize_t): int64
                                   {.cdecl, exportc: "planted_3sat_clause_generator".} =
  if input.isNil or length < 5 or length > 83 or input[0] < 3 or input[0] > 16 or input[1] < 0 or input[1] > 32: return -1
  let n = int(input[0])
  let m = int(input[1])
  if length != csize_t(2+n+2*m): return -1
  for i in 0 ..< n:
    if input[2+i] != 0 and input[2+i] != 1: return -1
  let choices = n*(n-1)*(n-2) div 6
  var literals: array[96, int64]
  for clause in 0 ..< m:
    let raw = input[2+n+2*clause]
    let mask = input[3+n+2*clause]
    if raw < 0 or raw >= int64(choices) or mask < 1 or mask > 7: return -1
    var rank = int(raw)
    var next = 0
    for position in 0 ..< 3:
      var variable = next
      while variable < n-(2-position):
        let remaining = n-variable-1
        let ways = if position == 0: remaining*(remaining-1) div 2 elif position == 1: remaining else: 1
        if rank >= ways:
          rank -= ways
          inc variable
          continue
        let value = int64(variable+1)
        literals[3*clause+position] = if input[2+variable] == ((mask shr position) and 1): value else: -value
        next = variable+1
        break
  let bytes = 24*m
  if bytes > 0 and (output.isNil or capacity < csize_t(bytes)): return -2
  for i in 0 ..< 3*m:
    var bits = cast[uint64](literals[i])
    for b in 0 .. 7:
      output[8*i+b] = uint8(bits and 255'u64)
      bits = bits shr 8
  return int64(bytes)
