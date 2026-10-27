proc putI64(outp: ptr UncheckedArray[uint8], value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8: outp[b] = uint8((bits shr (8 * b)) and 255)

proc felsenstein_substitution_likelihood*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc.} =
  if input.isNil or length < 3 or length > 38: return -1
  let n = input[0]
  if n < 1 or n > 8: return -1
  var stack: array[8, array[2, int64]]
  var sp = 0
  var leaves = 0
  var joins = 0
  var edges = 0
  var at = 1
  while at < int(length):
    let tag = input[at]
    inc at
    if tag == 0:
      if at >= int(length) or input[at] < 0 or input[at] > 1 or sp >= 8: return -1
      if input[at] == 0: stack[sp] = [1'i64, 0'i64]
      else: stack[sp] = [0'i64, 1'i64]
      inc at; inc sp; inc leaves
    elif tag == 1:
      if at + 2 > int(length) or sp < 2 or input[at] < 0 or input[at] > 1 or input[at+1] < 0 or input[at+1] > 1: return -1
      let lm = input[at]; let rm = input[at+1]; at += 2
      let left = stack[sp-2]; let right = stack[sp-1]
      var next: array[2, int64]
      for parent in 0 .. 1:
        let l = if lm == 0: 4 * left[parent] else: 3 * left[parent] + left[1-parent]
        let r = if rm == 0: 4 * right[parent] else: 3 * right[parent] + right[1-parent]
        next[parent] = l * r
      stack[sp-2] = next; dec sp; inc joins; edges += 2
    else: return -1
  if leaves != n or joins != n-1 or sp != 1 or edges != 2*n-2: return -1
  let shift = 29 - 2 * edges
  if shift < 0: return -1
  let scaled = (stack[0][0] + stack[0][1]) shl shift
  if output.isNil or capacity < 8: return -2
  putI64(output, scaled)
  8
