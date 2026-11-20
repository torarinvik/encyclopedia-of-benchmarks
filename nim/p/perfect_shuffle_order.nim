const MaxDeckSize = 10000

proc perfect_shuffle_order*(input: ptr UncheckedArray[int64],
                            length: csize_t): int64
    {.cdecl, exportc: "perfect_shuffle_order".} =
  if input.isNil or length != csize_t(1):
    return -1
  let deckSizeWord = input[0]
  if deckSizeWord < 2 or deckSizeWord > int64(MaxDeckSize) or deckSizeWord mod 2 != 0:
    return -1
  let deckSize = int(deckSizeWord)
  let half = deckSize div 2

  var deck: array[MaxDeckSize, int64]
  var following: array[MaxDeckSize, int64]
  for index in 0 ..< deckSize:
    deck[index] = int64(index)

  var repetitions = 0'i64
  while true:
    for index in 0 ..< half:
      following[index * 2] = deck[index]
      following[index * 2 + 1] = deck[half + index]
    inc repetitions

    var restored = true
    for index in 0 ..< deckSize:
      if following[index] != int64(index):
        restored = false
        break
    if restored:
      return repetitions

    for index in 0 ..< deckSize:
      deck[index] = following[index]
