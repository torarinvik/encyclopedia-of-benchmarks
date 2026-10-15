proc golombs_sequence*(index: int64): int64 {.cdecl, exportc: "golombs_sequence".} =
  if index < 0 or index > 64: return -1
  if index == 0: return 1
  if index <= 2: return 2
  var queue: array[65, int64]
  queue[0] = 2
  var head = 0
  var tail = 1
  var generated = 3'i64
  var value = 3'i64
  while generated <= index:
    let repetitions = queue[head]
    head += 1
    var repeated = 0'i64
    while repeated < repetitions and generated <= index:
      queue[tail] = value
      tail += 1
      if generated == index: return value
      generated += 1
      repeated += 1
    value += 1
  return -1
