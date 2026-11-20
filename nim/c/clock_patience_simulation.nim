const
  ClockPileCount = 13
  ClockCardsPerPile = 4
  ClockCardCount = ClockPileCount * ClockCardsPerPile

proc clock_patience_simulation*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "clock_patience_simulation".} =
  if values == nil or length != csize_t(ClockCardCount): return -1
  var rankCounts: array[ClockPileCount + 1, int]
  for index in 0 ..< ClockCardCount:
    let rank = values[index]
    if rank < 1 or rank > int64(ClockPileCount): return -1
    inc rankCounts[int(rank)]
  for rank in 1 .. ClockPileCount:
    if rankCounts[rank] != ClockCardsPerPile: return -1

  var nextCard: array[ClockPileCount, int]
  var pile = ClockPileCount - 1
  var revealed = 0
  while nextCard[pile] < ClockCardsPerPile:
    let rank = values[pile * ClockCardsPerPile + nextCard[pile]]
    inc nextCard[pile]
    inc revealed
    pile = int(rank - 1)
  if revealed == ClockCardCount: 1 else: 0
