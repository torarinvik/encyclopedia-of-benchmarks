## Count task assignments with one distinct eligible task per person.
proc assignment_using_bitmask*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "assignment_using_bitmask".} =
  if length < 2: return -1
  let people = input[0]
  let tasks = input[1]
  if people < 0 or people > 10 or tasks < 0 or tasks > 10 or length != csize_t(2 + people):
    return -1
  let validTasks = (1'i64 shl int(tasks)) - 1
  for person in 0 ..< int(people):
    if input[person + 2] < 0 or input[person + 2] > validTasks: return -1

  let states = 1 shl int(people)
  var ways: array[4096, int64]
  var next: array[4096, int64]
  ways[0] = 1
  for task in 0 ..< int(tasks):
    for mask in 0 ..< states: next[mask] = 0
    for mask in 0 ..< states:
      let count = ways[mask]
      if count == 0: continue
      next[mask] += count
      for person in 0 ..< int(people):
        let bit = 1 shl person
        if (mask and bit) == 0 and (input[person + 2] and (1'i64 shl task)) != 0:
          next[mask or bit] += count
    ways = next
  ways[states - 1]
