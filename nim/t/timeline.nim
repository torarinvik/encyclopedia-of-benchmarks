const MaxInitialEvents = 16
const MaxCommands = 32
const MaxEvents = MaxInitialEvents + MaxCommands
const MaxParseableInputLength = 131
const MaxOutputWords = 691
const MaxOutputBytes = 5528

proc pushWord(words: var array[MaxOutputWords, int64], count: var int, value: int64) =
  words[count] = value
  inc count

proc timeline*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "timeline".} =
  if input == nil or inputLength < 2 or inputLength > MaxParseableInputLength.csize_t: return -1
  if input[0] < 0 or input[0] > MaxInitialEvents: return -1
  let initialCount = int(input[0])
  let commandCountIndex = 1 + 2 * initialCount
  if commandCountIndex >= int(inputLength) or input[commandCountIndex] < 0 or input[commandCountIndex] > MaxCommands: return -1
  let commandCount = int(input[commandCountIndex])
  if int(inputLength) != 2 + 2 * initialCount + 3 * commandCount: return -1

  var eventTimes: array[MaxEvents, int64]
  var eventValues: array[MaxEvents, int64]
  var operations: array[MaxCommands, int64]
  var firstArguments: array[MaxCommands, int64]
  var secondArguments: array[MaxCommands, int64]
  var eventCount = initialCount
  for index in 0 ..< initialCount:
    let time = input[1 + 2 * index]
    let value = input[2 + 2 * index]
    if time < 0 or time > 1_000_000 or value < -32 or value > 32: return -1
    eventTimes[index] = time
    eventValues[index] = value
  # Stable insertion sort matches the constructor's OrderBy.
  for index in 1 ..< initialCount:
    let time = eventTimes[index]
    let value = eventValues[index]
    var position = index
    while position > 0 and eventTimes[position - 1] > time:
      eventTimes[position] = eventTimes[position - 1]
      eventValues[position] = eventValues[position - 1]
      dec position
    eventTimes[position] = time
    eventValues[position] = value

  var offset = commandCountIndex + 1
  for index in 0 ..< commandCount:
    let opcode = input[offset]
    let first = input[offset + 1]
    let second = input[offset + 2]
    if opcode < 0 or opcode > 14: return -1
    if opcode <= 2:
      if first < 0 or first > 1_000_000 or second < -32 or second > 32: return -1
    elif opcode in {3'i64, 4'i64, 5'i64, 6'i64, 8'i64}:
      if first < 0 or first > 1_000_000 or second != 0: return -1
    elif opcode == 7 or opcode == 9:
      if first < -32 or first > 32 or second != 0: return -1
    elif first != 0 or second != 0: return -1
    operations[index] = opcode
    firstArguments[index] = first
    secondArguments[index] = second
    offset += 3

  var words: array[MaxOutputWords, int64]
  var wordCount = 0
  for command in 0 ..< commandCount:
    let opcode = operations[command]
    let first = firstArguments[command]
    let second = secondArguments[command]
    let countIndex = wordCount + 1
    pushWord(words, wordCount, opcode)
    pushWord(words, wordCount, 0)

    if opcode == 0:
      eventTimes[eventCount] = first
      eventValues[eventCount] = second
      inc eventCount
    elif opcode == 1:
      var found = false
      for index in 0 ..< eventCount:
        if eventTimes[index] == first and eventValues[index] == second: found = true
      pushWord(words, wordCount, if found: 1 else: 0)
    elif opcode == 2:
      var found = -1
      for index in 0 ..< eventCount:
        if eventTimes[index] == first and eventValues[index] == second:
          found = index
          break
      if found >= 0:
        for index in found + 1 ..< eventCount:
          eventTimes[index - 1] = eventTimes[index]
          eventValues[index - 1] = eventValues[index]
        dec eventCount
        pushWord(words, wordCount, 1)
      else: pushWord(words, wordCount, 0)
    elif opcode == 3:
      for index in 0 ..< eventCount:
        if eventTimes[index] == first: pushWord(words, wordCount, eventValues[index])
    elif opcode == 4 or opcode == 5 or opcode == 10 or opcode == 12:
      var unique: array[MaxEvents, int64]
      var uniqueCount = 0
      for index in 0 ..< eventCount:
        var seen = false
        for prior in 0 ..< index:
          if eventTimes[prior] == eventTimes[index]: seen = true
        if not seen and (opcode == 10 or opcode == 12 or
            (opcode == 4 and eventTimes[index] < first) or
            (opcode == 5 and eventTimes[index] > first)):
          unique[uniqueCount] = eventTimes[index]
          inc uniqueCount
      if opcode == 4 or opcode == 5:
        for index in 1 ..< uniqueCount:
          let value = unique[index]
          var position = index
          while position > 0 and unique[position - 1] > value:
            unique[position] = unique[position - 1]
            dec position
          unique[position] = value
      if opcode == 12: pushWord(words, wordCount, int64(uniqueCount))
      else:
        for index in 0 ..< uniqueCount: pushWord(words, wordCount, unique[index])
    elif opcode == 6 or opcode == 7:
      let byTime = opcode == 6
      var existed = false
      var write = 0
      for index in 0 ..< eventCount:
        let matches = if byTime: eventTimes[index] == first else: eventValues[index] == first
        if matches: existed = true
        else:
          eventTimes[write] = eventTimes[index]
          eventValues[write] = eventValues[index]
          inc write
      eventCount = write
      pushWord(words, wordCount, if existed: 1 else: 0)
    elif opcode == 8 or opcode == 9:
      var found = false
      for index in 0 ..< eventCount:
        if (opcode == 8 and eventTimes[index] == first) or (opcode == 9 and eventValues[index] == first): found = true
      pushWord(words, wordCount, if found: 1 else: 0)
    elif opcode == 11:
      for index in 0 ..< eventCount: pushWord(words, wordCount, eventValues[index])
    elif opcode == 13: pushWord(words, wordCount, int64(eventCount))
    else: eventCount = 0

    words[countIndex] = int64(wordCount - countIndex - 1)

  pushWord(words, wordCount, -1)
  pushWord(words, wordCount, int64(eventCount))
  for index in 0 ..< eventCount:
    pushWord(words, wordCount, eventTimes[index])
    pushWord(words, wordCount, eventValues[index])
  let outputBytes = wordCount * 8
  if output == nil or capacity < csize_t(outputBytes) or outputBytes > MaxOutputBytes: return -2
  for index in 0 ..< wordCount:
    let bits = cast[uint64](words[index])
    for byteIndex in 0 ..< 8:
      output[index * 8 + byteIndex] = uint8((bits shr (byteIndex * 8)) and 0xff'u64)
  int64(outputBytes)
