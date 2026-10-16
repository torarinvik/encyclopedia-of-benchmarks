const MaxTotal = 36
const Scale = 10_000_000'i64

proc distribution(sides, dice: int64, output: var array[37, int64]) =
  var current: array[37, int64]
  var next: array[37, int64]
  current[0] = 1
  for die in 0'i64..<dice:
    for total in 0..MaxTotal: next[total] = 0
    for total in 0..MaxTotal:
      if current[total] != 0:
        for face in 1'i64..sides: next[total + int(face)] += current[total]
    current = next
  output = current

proc problem205*(placeholder: int64): int64 {.cdecl, exportc: "problem205".} =
  if placeholder != 0: return -1
  var peter, colin: array[37, int64]
  distribution(4, 9, peter)
  distribution(6, 6, colin)
  var wins = 0'i64
  var colinBelow = 0'i64
  for total in 0..MaxTotal:
    if total >= 9: wins += peter[total] * colinBelow
    colinBelow += colin[total]
  let games = 262_144'i64 * 46_656
  let scaled = wins * Scale
  var rounded = scaled div games
  let remainder = scaled mod games
  if 2 * remainder > games or (2 * remainder == games and rounded mod 2 != 0): inc rounded
  rounded
