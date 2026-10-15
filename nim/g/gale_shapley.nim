## Proposer-proposing Gale-Shapley stable matching for complete preferences.
proc gale_shapley*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "gale_shapley".} =
  if values == nil or length < 1 or length > 66 or values[0] < 0 or values[0] > 5:
    return -2
  let count = csize_t(values[0])
  if length != 1 + 2 * count * count:
    return -2
  var ranks: array[5, array[5, int64]]
  var seen: array[5, bool]
  for proposer in 0 ..< count:
    for index in 0 ..< count: seen[index] = false
    for rank in 0 ..< count:
      let accepter = values[1 + proposer * count + rank]
      if accepter < 0 or csize_t(accepter) >= count or seen[csize_t(accepter)]:
        return -2
      seen[csize_t(accepter)] = true
  let accepterOffset = 1 + count * count
  for accepter in 0 ..< count:
    for index in 0 ..< count: seen[index] = false
    for rank in 0 ..< count:
      let proposer = values[accepterOffset + accepter * count + rank]
      if proposer < 0 or csize_t(proposer) >= count or seen[csize_t(proposer)]:
        return -2
      seen[csize_t(proposer)] = true
      ranks[accepter][csize_t(proposer)] = int64(rank)
  if outputCapacity < count or (count != 0 and output == nil):
    return -2

  var matchedProposer: array[5, int64]
  var matchedAccepter: array[5, int64]
  var nextChoice: array[5, csize_t]
  for index in 0 ..< count:
    matchedProposer[index] = -1
    matchedAccepter[index] = -1
  while true:
    var proposer = csize_t(0)
    while proposer < count and matchedAccepter[proposer] != -1:
      inc proposer
    if proposer == count:
      break
    let accepter = csize_t(values[1 + proposer * count + nextChoice[proposer]])
    inc nextChoice[proposer]
    let current = matchedProposer[accepter]
    if current == -1 or ranks[accepter][proposer] < ranks[accepter][csize_t(current)]:
      if current != -1:
        matchedAccepter[csize_t(current)] = -1
      matchedProposer[accepter] = int64(proposer)
      matchedAccepter[proposer] = int64(accepter)
  for proposer in 0 ..< count:
    output[proposer] = uint8(matchedAccepter[proposer])
  int64(count)
