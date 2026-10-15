proc josephus_problem_simulation*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "josephus_problem_simulation".} =
  if length != 2: return -1
  let n = values[0]
  let step = values[1]
  if n < 1 or n > 512 or step < 1: return -1
  var people: array[512, int64]
  var remaining = csize_t(n)
  for i in 0 ..< remaining: people[i] = int64(i) + 1
  var current = csize_t(0)
  while remaining > 1:
    let offset = csize_t((step - 1) mod int64(remaining))
    let removed = (current + offset) mod remaining
    var i = removed
    while i + 1 < remaining:
      people[i] = people[i + 1]
      inc i
    dec remaining
    current = removed mod remaining
  people[0]
