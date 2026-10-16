proc putI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8: output[offset+b] = uint8((bits shr (8*b)) and 0xff'u64)

proc viterbi*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "viterbi".} =
  if input.isNil or length < 1 or length > 64: return -1
  for i in 0 ..< int(length):
    if input[i] < 0 or input[i] > 2: return -1
  if output.isNil or capacity < length * 8: return -2
  let tr: array[2, array[2, float64]] = [[0.7, 0.3], [0.4, 0.6]]
  let em: array[2, array[3, float64]] = [[0.5, 0.4, 0.1], [0.1, 0.3, 0.6]]
  var score = [0.6 * em[0][int(input[0])], 0.4 * em[1][int(input[0])]]
  var back: array[64, array[2, int]]
  for t in 1 ..< int(length):
    var next: array[2, float64]
    for s in 0 ..< 2:
      let a = score[0] * tr[0][s] * em[s][int(input[t])]
      let b = score[1] * tr[1][s] * em[s][int(input[t])]
      let prior = if b > a: 1 else: 0
      back[t][s] = prior
      next[s] = if prior == 0: a else: b
    score = next
  var state = if score[1] > score[0]: 1 else: 0
  var path: array[64, int]
  path[int(length)-1] = state
  for t in countdown(int(length)-1, 1):
    state = back[t][state]
    path[t-1] = state
  for i in 0 ..< int(length): putI64(output, i*8, int64(path[i]))
  int64(length * 8)
