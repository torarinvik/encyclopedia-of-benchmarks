## Uncompiled and unexecuted weighted-binary-search draft.
proc evaluate(input: ptr UncheckedArray[int64], n: int, penalty: int64): tuple[score, count: int64] =
  var two = (score: 0'i64, count: 0'i64)
  var one = two
  for i in 0 ..< n:
    let take = (score: two.score+input[2+i]-penalty, count: two.count+1)
    var current = one
    if take.score > one.score or (take.score == one.score and take.count > one.count): current = take
    two = one
    one = current
  one

proc wqs_path_independent_set*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "wqs_path_independent_set".} =
  if input.isNil or length < 2 or length > 130: return -1000000000
  if input[0] < 0 or input[0] > 128 or input[1] < 0 or input[1] > (input[0]+1) div 2: return -1000000000
  let n = int(input[0])
  if length != csize_t(n+2): return -1000000000
  for i in 0 ..< n:
    if input[2+i] < -1000 or input[2+i] > 1000: return -1000000000
  var low = -256001'i64
  var high = 256001'i64
  while low < high:
    let middle = low+(high-low+1) div 2
    if evaluate(input, n, middle).count >= input[1]: low = middle
    else: high = middle-1
  evaluate(input, n, low).score+low*input[1]
