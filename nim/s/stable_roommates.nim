const
  MaxN = 8
  MaxInputLength = 58
  PreferenceStride = MaxN + 1

proc hasStableRoommates(n: int, preferences: var array[MaxN * PreferenceStride, int],
                        ranking: var array[MaxN * MaxN, int]): bool =
  var leftmost: array[MaxN, int]
  var rightmost: array[MaxN, int]
  var proposedTo: array[MaxN, bool]

  for person in 0 ..< n:
    leftmost[person] = 0
    rightmost[person] = n - 1

  var proposer = 0
  var nextChoice = 0
  for start in 0 ..< n:
    proposer = start
    var steps = 0
    while true:
      if leftmost[proposer] > rightmost[proposer] or leftmost[proposer] >= n:
        return false
      nextChoice = preferences[proposer * PreferenceStride + leftmost[proposer]]
      if nextChoice == proposer: return false
      var current = preferences[nextChoice * PreferenceStride + rightmost[nextChoice]]
      while ranking[nextChoice * MaxN + proposer] > ranking[nextChoice * MaxN + current]:
        inc leftmost[proposer]
        if leftmost[proposer] > rightmost[proposer] or leftmost[proposer] >= n:
          return false
        nextChoice = preferences[proposer * PreferenceStride + leftmost[proposer]]
        if nextChoice == proposer: return false
        current = preferences[nextChoice * PreferenceStride + rightmost[nextChoice]]
      rightmost[nextChoice] = ranking[nextChoice * MaxN + proposer]
      proposer = current
      if not proposedTo[nextChoice]:
        proposedTo[nextChoice] = true
        break
      inc steps
      if steps > n * n: return false

  if proposer != nextChoice: return false
  for person in 0 ..< n:
    if leftmost[person] > rightmost[person]: return false

  var second: array[MaxN, int]
  for person in 0 ..< n:
    second[person] = leftmost[person] + 1

  var firstUnmatched = 0
  var firstInCycle = 0
  var tail: array[MaxN, bool]
  var cycle: array[MaxN + 1, int]

  while true:
    while firstUnmatched < n and leftmost[firstUnmatched] == rightmost[firstUnmatched]:
      inc firstUnmatched
    if firstUnmatched >= n:
      for person in 0 ..< n:
        let partner = preferences[person * PreferenceStride + leftmost[person]]
        if partner == person or preferences[partner * PreferenceStride + leftmost[partner]] != person:
          return false
      return true

    var visited: array[MaxN, bool]
    var person: int
    var position: int
    if firstInCycle > 0:
      visited = tail
      person = cycle[firstInCycle - 1]
      position = firstInCycle - 1
    else:
      person = firstUnmatched
      position = 0

    var repeatedPerson = -1
    while true:
      if position >= MaxN + 1: return false
      cycle[position] = person
      inc position
      visited[person] = true

      var listPosition = second[person]
      var choice = -1
      while listPosition < n:
        let candidate = preferences[person * PreferenceStride + listPosition]
        inc listPosition
        if candidate == person: return false
        if ranking[candidate * MaxN + person] <= rightmost[candidate]:
          choice = candidate
          break
      if choice < 0: return false
      second[person] = listPosition - 1
      let nextPerson = preferences[choice * PreferenceStride + rightmost[choice]]
      if visited[nextPerson]:
        repeatedPerson = nextPerson
        break
      person = nextPerson

    let lastInCycle = position - 1
    tail = visited
    var cycleStart = position
    while cycleStart > 0:
      dec cycleStart
      let member = cycle[cycleStart]
      tail[member] = false
      if member == repeatedPerson:
        firstInCycle = cycleStart
        break
    if cycleStart == 0 and cycle[cycleStart] != repeatedPerson: return false

    for index in firstInCycle .. lastInCycle:
      let cyclePerson = cycle[index]
      leftmost[cyclePerson] = second[cyclePerson]
      second[cyclePerson] = leftmost[cyclePerson] + 1
      if leftmost[cyclePerson] >= n: return false
      let nextChoiceInCycle = preferences[cyclePerson * PreferenceStride + leftmost[cyclePerson]]
      rightmost[nextChoiceInCycle] = ranking[nextChoiceInCycle * MaxN + cyclePerson]

    for index in firstInCycle .. lastInCycle:
      let cyclePerson = cycle[index]
      if leftmost[cyclePerson] > rightmost[cyclePerson]: return false

proc stable_roommates*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "stable_roommates".} =
  if input.isNil or length < 1 or length > csize_t(MaxInputLength): return -1
  let nArg = input[0]
  if nArg < 2 or nArg > MaxN or nArg mod 2 != 0: return -1
  let n = int(nArg)
  if length != csize_t(1 + n * (n - 1)): return -1

  var preferences: array[MaxN * PreferenceStride, int]
  var ranking: array[MaxN * MaxN, int]
  var cursor = 1
  for person in 0 ..< n:
    var seen: array[MaxN, bool]
    for rank in 0 ..< n - 1:
      let choice64 = input[cursor]
      inc cursor
      if choice64 < 0 or choice64 >= nArg or choice64 == int64(person): return -1
      let choice = int(choice64)
      if seen[choice]: return -1
      seen[choice] = true
      preferences[person * PreferenceStride + rank] = choice
      ranking[person * MaxN + choice] = rank
    preferences[person * PreferenceStride + n - 1] = person
    ranking[person * MaxN + person] = n - 1

  if hasStableRoommates(n, preferences, ranking): 1 else: 0
