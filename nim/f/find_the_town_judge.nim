## Find the unique person trusted by everyone else and who trusts nobody.
const MaxPeople = 1000
const MaxTrustRows = 10000

proc find_the_town_judge*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "find_the_town_judge".} =
  if length < 2 or length > 20002 or values == nil: return -2
  let people = values[0]
  let trustCount = values[1]
  if people < 1 or people > MaxPeople or trustCount < 0 or trustCount > MaxTrustRows: return -2
  let edgeCount = int(trustCount)
  if length != csize_t(2 + 2 * edgeCount): return -2

  var incoming, outgoing: array[MaxPeople + 1, int64]
  for edge in 0 ..< edgeCount:
    let from = values[2 + 2 * edge]
    let to = values[3 + 2 * edge]
    if from < 1 or from > people or to < 1 or to > people or from == to: return -2
    inc outgoing[int(from)]
    inc incoming[int(to)]

  var judge = -1'i64
  for person in 1 .. int(people):
    if incoming[person] == people - 1 and outgoing[person] == 0:
      if judge != -1: return -1
      judge = int64(person)
  judge
