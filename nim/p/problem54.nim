import std/algorithm

const DealCount = 1000
const ValuesPerDeal = 10

type Score = array[6, int64]
type HandCards = array[5, int64]

proc rankHand(cards: HandCards): Score =
  var ranks: array[5, int64]
  var suits: array[5, int64]
  var counts: array[15, int]
  for i in 0..<5:
    ranks[i] = cards[i] div 4 + 2
    suits[i] = cards[i] mod 4
    inc counts[int(ranks[i])]
  ranks.sort(order = SortOrder.Descending)
  var score: Score
  var flush = true
  for suit in suits:
    if suit != suits[0]: flush = false
  var distinct = true
  for rank in 2..14:
    if counts[rank] > 1: distinct = false
  var straightHigh: int64 = 0
  if distinct and ranks[0] - ranks[4] == 4: straightHigh = ranks[0]
  elif distinct and ranks == [14'i64, 5, 4, 3, 2]: straightHigh = 5
  var four: int64 = 0
  var three: int64 = 0
  var pairHigh: int64 = 0
  var pairLow: int64 = 0
  var singles: array[5, int64]
  var singleCount = 0
  for rank in countdown(14, 2):
    case counts[rank]
    of 4: four = rank.int64
    of 3: three = rank.int64
    of 2:
      if pairHigh == 0: pairHigh = rank.int64
      else: pairLow = rank.int64
    of 1:
      singles[singleCount] = rank.int64
      inc singleCount
    else: discard
  if flush and straightHigh != 0:
    score[0] = if straightHigh == 14: 9 else: 8
    score[1] = straightHigh
  elif four != 0:
    score[0] = 7; score[1] = four; score[2] = singles[0]
  elif three != 0 and pairHigh != 0:
    score[0] = 6; score[1] = three; score[2] = pairHigh
  elif flush:
    score[0] = 5
    for i in 0..<5: score[i + 1] = ranks[i]
  elif straightHigh != 0:
    score[0] = 4; score[1] = straightHigh
  elif three != 0:
    score[0] = 3; score[1] = three; score[2] = singles[0]; score[3] = singles[1]
  elif pairLow != 0:
    score[0] = 2; score[1] = pairHigh; score[2] = pairLow; score[3] = singles[0]
  elif pairHigh != 0:
    score[0] = 1; score[1] = pairHigh; score[2] = singles[0]; score[3] = singles[1]; score[4] = singles[2]
  else:
    score[0] = 0
    for i in 0..<5: score[i + 1] = ranks[i]
  score

proc problem54*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "problem54".} =
  if input == nil or length != csize_t(DealCount * ValuesPerDeal): return -1
  var wins: int64 = 0
  for deal in 0..<DealCount:
    let offset = deal * ValuesPerDeal
    for i in 0..<ValuesPerDeal:
      let card = input[offset + i]
      if card < 0 or card >= 52: return -1
      for previous in 0..<i:
        if input[offset + previous] == card: return -1
    var firstCards, secondCards: HandCards
    for i in 0..<5:
      firstCards[i] = input[offset + i]
      secondCards[i] = input[offset + 5 + i]
    if rankHand(firstCards) > rankHand(secondCards): inc wins
  wins
