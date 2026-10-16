proc solve(chain: var array[32, int64], length: int, goal: int64, depth: int): bool =
  let last = chain[length - 1]
  for index in 0 ..< length:
    let next = chain[index] + last
    if next == goal: return true
    if next > goal: break
    if length < depth:
      chain[length] = next
      if solve(chain, length + 1, goal, depth): return true
  false

proc problem122*(maximum: int64): int64 {.cdecl, exportc: "problem122".} =
  if maximum < 0 or maximum > 200: return -1
  var total = 0'i64
  for goal in 2 .. int(maximum):
    var chain: array[32, int64]
    chain[0] = 1
    var depth = 0
    while true:
      inc depth
      chain[0] = 1
      if solve(chain, 1, goal.int64, depth): break
    total += depth.int64
  total
