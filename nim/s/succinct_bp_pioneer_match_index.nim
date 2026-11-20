const
  MaxPairs = 32
  MaxBits = 2 * MaxPairs
  MaxInput = 1 + MaxBits + 1
  MaxOutput = 8 * (1 + MaxBits)
  BlockSize = 8
  BaseBits = 16
  MaxLevels = 3
  Missing = 255'u8

type
  Index = object
    length: int
    bits: array[MaxBits, uint8]
    localMate: array[MaxBits, uint8]
    depth: array[MaxBits + 1, uint8]
    openPioneers: array[MaxBits, uint8]
    openPioneerCount: int
    closePioneers: array[MaxBits, uint8]
    closePioneerCount: int
    family: array[MaxBits, uint8]
    familyRank: array[MaxBits, uint8]
    familyCount: int
    groupSource: array[MaxBits, uint8]
    groupTarget: array[MaxBits, uint8]
    groupDepth: array[MaxBits, uint8]
    groupCount: int
    openPositions: array[MaxBits, uint8]
    openGroups: array[MaxBits, uint8]
    openCount: int
    closePositions: array[MaxBits, uint8]
    closeGroups: array[MaxBits, uint8]
    closeCount: int
  Context = object
    levels: array[MaxLevels, Index]

proc ensureGroup(idx: ptr Index, source, target, depth: int): int =
  for group in 0 ..< idx[].groupCount:
    if int(idx[].groupSource[group]) == source and
        int(idx[].groupTarget[group]) == target and
        int(idx[].groupDepth[group]) == depth:
      return group
  let group = idx[].groupCount
  idx[].groupSource[group] = uint8(source)
  idx[].groupTarget[group] = uint8(target)
  idx[].groupDepth[group] = uint8(depth)
  inc idx[].groupCount
  group

proc findGroup(idx: ptr Index, source, target, depth: int): int =
  for group in 0 ..< idx[].groupCount:
    if int(idx[].groupSource[group]) == source and
        int(idx[].groupTarget[group]) == target and
        int(idx[].groupDepth[group]) == depth:
      return group
  -1

proc build(ctx: ptr Context, level: int, bits: openArray[uint8]): bool =
  if level >= MaxLevels or bits.len > MaxBits:
    return false
  let idx = addr ctx[].levels[level]
  idx[].length = bits.len
  for position in 0 ..< bits.len:
    idx[].bits[position] = bits[position]
    idx[].localMate[position] = Missing
    idx[].familyRank[position] = Missing
    if bits[position] == 1'u8:
      idx[].depth[position + 1] = idx[].depth[position] + 1'u8
    else:
      idx[].depth[position + 1] = idx[].depth[position] - 1'u8

  var stack: array[MaxBits, uint8]
  var top = 0
  var mate: array[MaxBits, uint8]
  for position in 0 ..< bits.len:
    if bits[position] == 1'u8:
      stack[top] = uint8(position)
      inc top
    else:
      dec top
      let opening = int(stack[top])
      mate[opening] = uint8(position)
      mate[position] = uint8(opening)

  if bits.len <= BaseBits:
    for position in 0 ..< bits.len:
      idx[].localMate[position] = mate[position]
    return true

  var far: array[MaxBits, bool]
  for position in 0 ..< bits.len:
    let partner = int(mate[position])
    if partner div BlockSize != position div BlockSize:
      far[position] = true
    else:
      idx[].localMate[position] = mate[position]

  var seenOpen: array[MaxBits div BlockSize, bool]
  var lastOpenTarget: array[MaxBits div BlockSize, uint8]
  for position in 0 ..< bits.len:
    if bits[position] == 1'u8 and far[position]:
      let block = position div BlockSize
      let target = int(mate[position]) div BlockSize
      if not seenOpen[block] or int(lastOpenTarget[block]) != target:
        idx[].openPioneers[idx[].openPioneerCount] = uint8(position)
        inc idx[].openPioneerCount
      seenOpen[block] = true
      lastOpenTarget[block] = uint8(target)

  var seenClose: array[MaxBits div BlockSize, bool]
  var lastCloseTarget: array[MaxBits div BlockSize, uint8]
  if bits.len > 0:
    for position in countdown(bits.len - 1, 0):
      if bits[position] == 0'u8 and far[position]:
        let block = position div BlockSize
        let target = int(mate[position]) div BlockSize
        if not seenClose[block] or int(lastCloseTarget[block]) != target:
          idx[].closePioneers[idx[].closePioneerCount] = uint8(position)
          inc idx[].closePioneerCount
        seenClose[block] = true
        lastCloseTarget[block] = uint8(target)

  var inFamily: array[MaxBits, bool]
  for i in 0 ..< idx[].openPioneerCount:
    let position = int(idx[].openPioneers[i])
    inFamily[position] = true
    inFamily[int(mate[position])] = true
  for i in 0 ..< idx[].closePioneerCount:
    let position = int(idx[].closePioneers[i])
    inFamily[position] = true
    inFamily[int(mate[position])] = true
  for position in 0 ..< bits.len:
    if inFamily[position]:
      idx[].familyRank[position] = uint8(idx[].familyCount)
      idx[].family[idx[].familyCount] = uint8(position)
      inc idx[].familyCount

  for position in 0 ..< bits.len:
    if not far[position]:
      continue
    let source = position div BlockSize
    let target = int(mate[position]) div BlockSize
    let depth = if bits[position] == 1'u8:
      int(idx[].depth[position])
    else:
      int(idx[].depth[position + 1])
    let group = ensureGroup(idx, source, target, depth)
    if bits[position] == 1'u8:
      idx[].openPositions[idx[].openCount] = uint8(position)
      idx[].openGroups[idx[].openCount] = uint8(group)
      inc idx[].openCount
    else:
      idx[].closePositions[idx[].closeCount] = uint8(position)
      idx[].closeGroups[idx[].closeCount] = uint8(group)
      inc idx[].closeCount

  var childBits: array[MaxBits, uint8]
  for rank in 0 ..< idx[].familyCount:
    childBits[rank] = bits[int(idx[].family[rank])]
  if idx[].familyCount == 0:
    return true
  build(ctx, level + 1, childBits.toOpenArray(0, idx[].familyCount - 1))

proc selectPosition(idx: ptr Index, group, rank: int, openings: bool): int =
  var current = 0
  if openings:
    for i in 0 ..< idx[].openCount:
      if int(idx[].openGroups[i]) == group:
        if current == rank:
          return int(idx[].openPositions[i])
        inc current
  else:
    for i in 0 ..< idx[].closeCount:
      if int(idx[].closeGroups[i]) == group:
        if current == rank:
          return int(idx[].closePositions[i])
        inc current
  -1

proc rankPosition(idx: ptr Index, group, position: int, openings: bool): int =
  var rank = 0
  if openings:
    for i in 0 ..< idx[].openCount:
      if int(idx[].openGroups[i]) == group:
        if int(idx[].openPositions[i]) == position:
          return rank
        inc rank
  else:
    for i in 0 ..< idx[].closeCount:
      if int(idx[].closeGroups[i]) == group:
        if int(idx[].closePositions[i]) == position:
          return rank
        inc rank
  -1

proc match(ctx: ptr Context, level, position: int): int =
  let idx = addr ctx[].levels[level]
  if int(idx[].localMate[position]) != int(Missing):
    return int(idx[].localMate[position])
  let source = position div BlockSize
  if idx[].bits[position] == 1'u8:
    var pioneer = -1
    for i in 0 ..< idx[].openPioneerCount:
      let candidate = int(idx[].openPioneers[i])
      if candidate div BlockSize == source and candidate <= position:
        pioneer = candidate
    if pioneer < 0:
      return -1
    let childPosition = int(idx[].familyRank[pioneer])
    let childMate = match(ctx, level + 1, childPosition)
    if childMate < 0:
      return -1
    let anchor = int(idx[].family[childMate])
    let target = anchor div BlockSize
    let depth = int(idx[].depth[position])
    let group = findGroup(idx, source, target, depth)
    let opposite = findGroup(idx, target, source, depth)
    if group < 0 or opposite < 0:
      return -1
    let rank = rankPosition(idx, group, position, true)
    if rank < 0:
      return -1
    return selectPosition(idx, opposite, rank, false)

  var pioneer = -1
  for i in 0 ..< idx[].closePioneerCount:
    let candidate = int(idx[].closePioneers[i])
    if candidate div BlockSize == source and candidate >= position:
      if pioneer < 0 or candidate < pioneer:
        pioneer = candidate
  if pioneer < 0:
    return -1
  let childPosition = int(idx[].familyRank[pioneer])
  let childMate = match(ctx, level + 1, childPosition)
  if childMate < 0:
    return -1
  let anchor = int(idx[].family[childMate])
  let target = anchor div BlockSize
  let depth = int(idx[].depth[position + 1])
  let group = findGroup(idx, source, target, depth)
  let opposite = findGroup(idx, target, source, depth)
  if group < 0 or opposite < 0:
    return -1
  let rank = rankPosition(idx, group, position, false)
  if rank < 0:
    return -1
  selectPosition(idx, opposite, rank, true)

proc putI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc succinct_bp_pioneer_match_index*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "succinct_bp_pioneer_match_index".} =
  if input == nil or length < 3 or length > csize_t(MaxInput):
    return -1
  let pairs = input[0]
  if pairs < 1 or pairs > MaxPairs or length != csize_t(1 + 2 * pairs):
    return -1
  let bitsLength = int(2 * pairs)
  var balance = 0
  for position in 0 ..< bitsLength:
    let bit = input[position + 1]
    if bit != 0 and bit != 1:
      return -1
    if bit == 1: inc balance else: dec balance
    if balance < 0: return -1
  if balance != 0: return -1
  let required = int(length) * 8
  if output == nil or capacity < csize_t(required):
    return -2

  var bits: array[MaxBits, uint8]
  for position in 0 ..< bitsLength:
    bits[position] = uint8(input[position + 1])
  var context: Context
  if not build(addr context, 0, bits.toOpenArray(0, bitsLength - 1)):
    return -1
  var answers: array[MaxBits, int]
  for position in 0 ..< bitsLength:
    answers[position] = match(addr context, 0, position)
    if answers[position] < 0:
      return -1
  putI64(output, 0, int64(bitsLength))
  for position in 0 ..< bitsLength:
    putI64(output, 8 * (position + 1), int64(answers[position]))
  int64(required)
