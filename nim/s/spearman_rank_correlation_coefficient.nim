import std/math

const InvalidResult = -1.0e300

proc assignRanks(values: ptr UncheckedArray[int64], offset, n: int, ranks: var array[3, float64]) =
  var order: array[3, int]
  for i in 0 ..< n: order[i] = i
  for i in 1 ..< n:
    let key = order[i]
    var j = i
    while j > 0 and values[offset + order[j - 1]] > values[offset + key]:
      order[j] = order[j - 1]
      dec j
    order[j] = key
  var i = 0
  while i < n:
    var j = i
    while j < n - 1 and values[offset + order[j + 1]] == values[offset + order[i]]: inc j
    let rank = (float64(i) + float64(j)) / 2.0 + 1.0
    for k in i .. j: ranks[order[k]] = rank
    i = j + 1

proc roundTenthTiesEven(value: float64): float64 =
  let scaled = value * 10.0
  let lower = floor(scaled)
  let fraction = scaled - lower
  var rounded = lower
  if fraction > 0.5 or (fraction == 0.5 and int64(lower) mod 2 != 0): rounded = lower + 1.0
  rounded / 10.0

proc spearman_rank_correlation_coefficient*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "spearman_rank_correlation_coefficient".} =
  if values == nil or length < 5: return InvalidResult
  let nValue = values[0]
  if nValue < 2 or nValue > 3 or length != 1 + 2 * csize_t(nValue): return InvalidResult
  let n = int(nValue)
  for i in 0 ..< n:
    if values[1 + i] < -1000 or values[1 + i] > 1000 or values[1 + n + i] < -1000 or values[1 + n + i] > 1000:
      return InvalidResult
  var rankX, rankY: array[3, float64]
  assignRanks(values, 1, n, rankX)
  assignRanks(values, 1 + n, n, rankY)
  var dSquared = 0.0
  for i in 0 ..< n:
    let difference = rankX[i] - rankY[i]
    dSquared += difference * difference
  let nf = float64(n)
  let rho = 1.0 - (6.0 * dSquared) / (nf * (nf * nf - 1.0))
  roundTenthTiesEven(rho)
