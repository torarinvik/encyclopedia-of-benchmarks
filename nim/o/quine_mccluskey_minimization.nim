const
  MaxVariables = 3
  MaxCubes = 27
  MaxStates = 256
  MaxInputLength = 9
  InfCost = 99

proc cubeValid(care, value: int, status: ptr UncheckedArray[int64], size: int): tuple[valid: bool, cover: uint32] =
  var cover = 0'u32
  for minterm in 0 ..< size:
    if (minterm and care) == value:
      if status[minterm] == 0: return (false, 0'u32)
      if status[minterm] == 1: cover = cover or (1'u32 shl minterm)
  (cover != 0, cover)

proc lexBetter(candidate, incumbent: uint32, count: int): bool =
  for index in 0 ..< count:
    let bit = 1'u32 shl index
    let left = (candidate and bit) != 0
    let right = (incumbent and bit) != 0
    if left != right: return left
  false

proc quine_mccluskey_minimization*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "quine_mccluskey_minimization".} =
  if input == nil or length < 2 or length > csize_t(MaxInputLength): return -1
  let nValue = input[0]
  if nValue < 1 or nValue > MaxVariables: return -1
  let n = int(nValue)
  let size = 1 shl n
  if length != csize_t(1 + size): return -1
  for minterm in 0 ..< size:
    if input[1 + minterm] < 0 or input[1 + minterm] > 2: return -1

  var cares: array[MaxCubes, int]
  var values: array[MaxCubes, int]
  var covers: array[MaxCubes, uint32]
  var literalCounts: array[MaxCubes, int]
  var primeCount = 0
  let full = size - 1
  for care in 0 .. full:
    for value in 0 .. full:
      if (value and not care) != 0: continue
      let cube = cubeValid(care, value, cast[ptr UncheckedArray[int64]](input[1].addr), size)
      if not cube.valid: continue
      var prime = true
      for variable in 0 ..< n:
        let bit = 1 shl variable
        if (care and bit) != 0 and cubeValid(care xor bit, value and not bit,
            cast[ptr UncheckedArray[int64]](input[1].addr), size).valid:
          prime = false
          break
      if prime:
        cares[primeCount] = care
        values[primeCount] = value
        covers[primeCount] = cube.cover
        var literalCount = 0
        for variable in 0 ..< n:
          if (care and (1 shl variable)) != 0: inc literalCount
        literalCounts[primeCount] = literalCount
        inc primeCount

  var onMask = 0'u32
  for minterm in 0 ..< size:
    if input[1 + minterm] == 1: onMask = onMask or (1'u32 shl minterm)
  let stateCount = 1 shl size
  var termCost: array[MaxStates, int]
  var literalCost: array[MaxStates, int]
  var selected: array[MaxStates, uint32]
  for state in 0 ..< stateCount:
    termCost[state] = InfCost
    literalCost[state] = InfCost
    selected[state] = 0
  termCost[0] = 0
  literalCost[0] = 0
  for index in 0 ..< primeCount:
    let primeBit = 1'u32 shl index
    var state = stateCount
    while state > 0:
      dec state
      if termCost[state] == InfCost: continue
      let destination = state or int(covers[index])
      if destination == state: continue
      let newTerms = termCost[state] + 1
      let newLiterals = literalCost[state] + literalCounts[index]
      let newSelected = selected[state] or primeBit
      var better = newTerms < termCost[destination]
      if newTerms == termCost[destination]:
        better = newLiterals < literalCost[destination]
        if newLiterals == literalCost[destination]: better = lexBetter(newSelected, selected[destination], primeCount)
      if better:
        termCost[destination] = newTerms
        literalCost[destination] = newLiterals
        selected[destination] = newSelected
  let chosen = selected[int(onMask)]
  var termCount = 0
  for index in 0 ..< primeCount:
    if (chosen and (1'u32 shl index)) != 0: inc termCount
  let outputBytes = csize_t(8 * (1 + 2 * termCount))
  if output == nil or capacity < outputBytes: return -2
  var words: array[17, int64]
  words[0] = int64(termCount)
  var cursor = 1
  for index in 0 ..< primeCount:
    if (chosen and (1'u32 shl index)) != 0:
      words[cursor] = int64(cares[index])
      inc cursor
      words[cursor] = int64(values[index])
      inc cursor
  for word in 0 ..< cursor:
    let bits = cast[uint64](words[word])
    for byte in 0 ..< 8:
      output[word * 8 + byte] = uint8((bits shr (8 * byte)) and 255)
  int64(outputBytes)
