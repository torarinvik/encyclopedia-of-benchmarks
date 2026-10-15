## Bottom-up minimum-square-count dynamic programming, bounded to 4096.
proc minimum_squares_to_represent_a_number*(input: int64): int64 {.cdecl, exportc: "minimum_squares_to_represent_a_number".} =
  if input < 0 or input > 4096: return -1
  if input == 0: return 1

  var answers: array[4097, int64]
  for index in 0..int(input): answers[index] = -1
  answers[0] = 0
  for value in 1..int(input):
    var best = high(int64)
    var root = 1
    while root <= value div root:
      let candidate = 1 + answers[value - root * root]
      if candidate < best: best = candidate
      inc root
    answers[value] = best
  answers[int(input)]
