const MaxVars = 5
const MaxClauses = 6
const MaxLits = MaxVars * MaxClauses

type Formula = object
  count: int
  lengths: array[MaxClauses, int]
  literals: array[MaxLits, int]
type Stats = object
  calls, tests, branches, maxDepth: int64

proc putI64(output: ptr UncheckedArray[uint8], word: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8: output[word * 8 + b] = uint8((bits shr (8 * b)) and 255)

proc shorten(f: Formula, k: int): Formula =
  var d: Formula
  d.count = f.count
  for c in 0 ..< f.count:
    d.lengths[c] = min(f.lengths[c], k)
    for j in 0 ..< d.lengths[c]: d.literals[c * MaxVars + j] = f.literals[c * MaxVars + j]
  d

proc exactSat(f: Formula, n: int, fixedMask, fixedValues: uint32): tuple[sat: bool, model: uint32] =
  for code in 0'u32 ..< (1'u32 shl n):
    var candidate = 0'u32
    for v in 0 ..< n:
      if ((code shr (n - v - 1)) and 1) != 0: candidate = candidate or (1'u32 shl v)
    if ((candidate xor fixedValues) and fixedMask) != 0: continue
    var all = true
    for c in 0 ..< f.count:
      var one = false
      for j in 0 ..< f.lengths[c]:
        let lit = f.literals[c * MaxVars + j]
        let truth = ((candidate shr (abs(lit) - 1)) and 1) != 0
        if (lit > 0 and truth) or (lit < 0 and not truth): one = true
      if not one: all = false
    if all: return (true, candidate)
  (false, 0'u32)

proc solve(f: Formula, n, k: int, fixedMask, fixedValues: uint32,
           depth: int64, stats: var Stats): tuple[sat: bool, model: uint32] =
  inc stats.calls
  stats.maxDepth = max(stats.maxDepth, depth)
  let d = shorten(f, k)
  inc stats.tests
  let base = exactSat(d, n, fixedMask, fixedValues)
  if base.sat: return base
  for branch in 0 ..< f.count:
    if d.lengths[branch] == 0: continue
    inc stats.branches
    var nextMask = fixedMask
    var nextValues = fixedValues
    var conflict = false
    for j in 0 ..< d.lengths[branch]:
      let lit = d.literals[branch * MaxVars + j]
      let bit = 1'u32 shl (abs(lit) - 1)
      let value = if lit < 0: bit else: 0'u32
      if (nextMask and bit) != 0 and (nextValues and bit) != value: conflict = true
      nextMask = nextMask or bit
      nextValues = (nextValues and not bit) or value
    if conflict or nextMask == fixedMask: continue
    var child: Formula
    let newlyFixed = nextMask and (not fixedMask)
    for c in 0 ..< f.count:
      let source = if c < branch: d else: f
      var satisfied = false
      var kept = 0
      for j in 0 ..< source.lengths[c]:
        let lit = source.literals[c * MaxVars + j]
        let bit = 1'u32 shl (abs(lit) - 1)
        if (newlyFixed and bit) != 0:
          let truth = (nextValues and bit) != 0
          if (lit > 0 and truth) or (lit < 0 and not truth): satisfied = true
        else:
          child.literals[child.count * MaxVars + kept] = lit
          inc kept
      if not satisfied:
        child.lengths[child.count] = kept
        inc child.count
    let result = solve(child, n, k, nextMask, nextValues, depth + 1, stats)
    if result.sat: return result
  (false, 0'u32)

proc procedure_s_general_cnf_sat*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "procedure_s_general_cnf_sat".} =
  if input.isNil or length < 3 or length > 39: return -1
  let n0 = input[0]; let m0 = input[1]; let k0 = input[2]
  if n0 < 1 or n0 > MaxVars or m0 < 0 or m0 > MaxClauses or k0 < 1 or k0 > n0: return -1
  let n = int(n0); let m = int(m0); let k = int(k0)
  var f: Formula
  f.count = m
  var at = 3
  for c in 0 ..< m:
    if at >= int(length) or input[at] < 1 or input[at] > n0: return -1
    let count = int(input[at]); inc at
    if at + count > int(length): return -1
    var seen = 0'u32
    f.lengths[c] = count
    for j in 0 ..< count:
      let value = input[at]; inc at
      if value == 0 or value > n0 or value < -n0: return -1
      let lit = int(value); let bit = 1'u32 shl (abs(lit) - 1)
      if (seen and bit) != 0: return -1
      seen = seen or bit
      f.literals[c * MaxVars + j] = lit
  if at != int(length): return -1
  var stats: Stats
  let answer = solve(f, n, k, 0'u32, 0'u32, 0, stats)
  if output.isNil or capacity < 48: return -2
  putI64(output, 0, if answer.sat: 1 else: 0)
  putI64(output, 1, if answer.sat: int64(answer.model) else: 0)
  putI64(output, 2, stats.calls); putI64(output, 3, stats.tests)
  putI64(output, 4, stats.branches); putI64(output, 5, stats.maxDepth)
  48
