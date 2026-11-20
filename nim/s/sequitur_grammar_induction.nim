## Clean-room bounded deterministic Sequitur grammar profile.
type
  Grammar = object
    symbols: array[16384, int32]
    lengths: array[256, int]
    live: array[256, bool]
    nextRule: int
  Duplicate = object
    found: bool
    r1, p1, r2, p2: int
    left, right: int32

proc replacePair(g: var Grammar, rule, position: int, token: int32) =
  for i in position+2 ..< g.lengths[rule]: g.symbols[rule*64+i-1] = g.symbols[rule*64+i]
  dec g.lengths[rule]
  g.symbols[rule*64+position] = token

proc findDuplicate(g: var Grammar): Duplicate =
  for r1 in 0 ..< g.nextRule:
    if g.live[r1]:
      for p1 in 0 ..< max(0, g.lengths[r1]-1):
        let left=g.symbols[r1*64+p1]
        let right=g.symbols[r1*64+p1+1]
        for r2 in r1 ..< g.nextRule:
          if g.live[r2]:
            let first = if r2 == r1: p1+2 else: 0
            for p2 in first ..< max(first, g.lengths[r2]-1):
              if g.symbols[r2*64+p2] == left and g.symbols[r2*64+p2+1] == right:
                return Duplicate(found: true, r1: r1, p1: p1, r2: r2, p2: p2, left: left, right: right)
  return Duplicate(found: false, r1: 0, p1: 0, r2: 0, p2: 0, left: 0, right: 0)

proc cleanupOne(g: var Grammar): bool =
  for target in 1 ..< g.nextRule:
    if g.live[target]:
      var count=0
      var parent=0
      var position=0
      let token=int32(256+target)
      for rule in 0 ..< g.nextRule:
        if g.live[rule]:
          for i in 0 ..< g.lengths[rule]:
            if g.symbols[rule*64+i] == token:
              inc count
              parent=rule
              position=i
      if count == 0:
        g.live[target]=false
        g.lengths[target]=0
        return true
      if count == 1:
        var copy: array[64, int32]
        let replacementLength=g.lengths[target]
        for i in 0 ..< replacementLength: copy[i]=g.symbols[target*64+i]
        let delta=replacementLength-1
        let oldLength=g.lengths[parent]
        if oldLength > position+1:
          for i in countdown(oldLength-1, position+1): g.symbols[parent*64+i+delta]=g.symbols[parent*64+i]
        for i in 0 ..< replacementLength: g.symbols[parent*64+position+i]=copy[i]
        g.lengths[parent]+=delta
        g.live[target]=false
        g.lengths[target]=0
        return true
  return false

proc normalize(g: var Grammar) =
  while true:
    while cleanupOne(g): discard
    let d=findDuplicate(g)
    if not d.found: return
    var existing = -1
    for rule in 1 ..< g.nextRule:
      if g.live[rule] and g.lengths[rule] == 2 and g.symbols[rule*64] == d.left and g.symbols[rule*64+1] == d.right:
        existing=rule
        break
    if existing >= 0:
      var rule=d.r1
      var position=d.p1
      if rule == existing and position == 0:
        rule=d.r2
        position=d.p2
      replacePair(g, rule, position, int32(256+existing))
    else:
      let fresh=g.nextRule
      inc g.nextRule
      g.live[fresh]=true
      g.lengths[fresh]=2
      g.symbols[fresh*64]=d.left
      g.symbols[fresh*64+1]=d.right
      let token=int32(256+fresh)
      replacePair(g, d.r2, d.p2, token)
      replacePair(g, d.r1, d.p1, token)

proc sequitur_grammar_induction*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "sequitur_grammar_induction".} =
  if input.isNil or length < 1 or length > 66: return -1
  if input[0] < 0 or input[0] > 64 or int(length) != int(input[0])+1: return -1
  let n=int(input[0])
  for i in 0 ..< n:
    if input[i+1] < 0 or input[i+1] > 255: return -1
  var g: Grammar
  g.live[0]=true
  g.nextRule=1
  for i in 0 ..< n:
    g.symbols[g.lengths[0]]=int32(input[i+1])
    inc g.lengths[0]
    normalize(g)
  var rules=0'i64
  var symbols=0'i64
  for rule in 0 ..< g.nextRule:
    if g.live[rule]:
      if rule != 0: inc rules
      symbols += int64(g.lengths[rule])
  1000*rules+symbols
