const
  MaxVertices = 8
  MaxInputLength = 9
  InvalidResult = -1'i64
  DegreeColorPlace = 43046721'i64

proc popcount(value: int64): int =
  var remaining = value
  while remaining != 0:
    result += int(remaining and 1)
    remaining = remaining shr 1

proc weisfeiler_lehman_color_refinement*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "weisfeiler_lehman_color_refinement".} =
  if input.isNil or length < 1 or length > MaxInputLength + 1: return InvalidResult
  if input[0] < 0 or input[0] > MaxVertices: return InvalidResult
  let n = int(input[0])
  if int(length) != 1 + n: return InvalidResult

  let allowed = (1'i64 shl n) - 1
  var adjacency: array[MaxVertices, int64]
  var colors: array[MaxVertices, int64]
  var nextColors: array[MaxVertices, int64]
  var classCount = 0
  for vertex in 0 ..< n:
    let mask = input[1 + vertex]
    if mask < 0 or (mask and not allowed) != 0 or (mask and (1'i64 shl vertex)) != 0:
      return InvalidResult
    adjacency[vertex] = mask
    colors[vertex] = int64(popcount(mask))
    var firstDegree = true
    for prior in 0 ..< vertex:
      if colors[prior] == colors[vertex]: firstDegree = false
      if ((adjacency[vertex] shr prior) and 1) != ((adjacency[prior] shr vertex) and 1):
        return InvalidResult
    if firstDegree: inc classCount
  if n == 0: return 0

  var stable = false
  while not stable:
    var keys: array[MaxVertices, int64]
    var uniqueKeys: array[MaxVertices, int64]
    var uniqueCount = 0
    for vertex in 0 ..< n:
      var neighborColors: array[MaxVertices, int64]
      var neighborCount = 0
      for neighbor in 0 ..< n:
        if (adjacency[vertex] and (1'i64 shl neighbor)) == 0: continue
        let value = colors[neighbor]
        var position = neighborCount
        while position > 0 and neighborColors[position - 1] > value:
          neighborColors[position] = neighborColors[position - 1]
          dec position
        neighborColors[position] = value
        inc neighborCount

      var suffix = 0'i64
      for slot in 0 ..< MaxVertices:
        suffix *= 9
        if slot < neighborCount: suffix += neighborColors[slot] + 1
      keys[vertex] = colors[vertex] * DegreeColorPlace + suffix

      var seen = false
      for prior in 0 ..< vertex:
        if keys[prior] == keys[vertex]: seen = true
      if not seen:
        uniqueKeys[uniqueCount] = keys[vertex]
        inc uniqueCount

    for index in 1 ..< uniqueCount:
      let value = uniqueKeys[index]
      var position = index
      while position > 0 and uniqueKeys[position - 1] > value:
        uniqueKeys[position] = uniqueKeys[position - 1]
        dec position
      uniqueKeys[position] = value

    for vertex in 0 ..< n:
      var rank = 0
      while uniqueKeys[rank] != keys[vertex]: inc rank
      nextColors[vertex] = int64(rank)
    if uniqueCount == classCount: stable = true
    classCount = uniqueCount
    for vertex in 0 ..< n: colors[vertex] = nextColors[vertex]

  var packed = 0'i64
  var place = 1'i64
  for vertex in 0 ..< n:
    packed += colors[vertex] * place
    place *= 9
  packed
