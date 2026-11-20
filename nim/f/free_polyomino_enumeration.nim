const
  MaxN = 8
  MaxShapes = 512
  LayerWords = MaxShapes * MaxN

proc canonical(xs, ys: array[MaxN, int64], size: int,
               result: var array[MaxN, int64]) =
  var best: array[MaxN, int64]
  var haveBest = false
  for mode in 0 ..< 8:
    var tx, ty, codes: array[MaxN, int64]
    var minX = 1000'i64
    var minY = 1000'i64
    for i in 0 ..< size:
      var a = if mode >= 4: ys[i] else: xs[i]
      var b = if mode >= 4: xs[i] else: ys[i]
      if (mode and 1) != 0: a = -a
      if (mode and 2) != 0: b = -b
      tx[i] = a
      ty[i] = b
      if a < minX: minX = a
      if b < minY: minY = b
    for i in 0 ..< size:
      codes[i] = (tx[i] - minX) * 8 + ty[i] - minY
      var j = i
      while j > 0 and codes[j] < codes[j - 1]:
        swap(codes[j], codes[j - 1])
        dec j
    var less = not haveBest
    if haveBest:
      for i in 0 ..< size:
        if codes[i] != best[i]:
          less = codes[i] < best[i]
          break
    if less:
      for i in 0 ..< size: best[i] = codes[i]
      haveBest = true
  for i in 0 ..< size: result[i] = best[i]

proc free_polyomino_enumeration*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "free_polyomino_enumeration".} =
  if input.isNil or length != 1 or input[0] < 1 or input[0] > MaxN: return -1
  let n = int(input[0])
  var shapes: array[2 * LayerWords, int64]
  var current = 0
  var shapeCount = 1
  let dx = [1, -1, 0, 0]
  let dy = [0, 0, 1, -1]
  for size in 1 ..< n:
    let next = 1 - current
    var nextCount = 0
    for s in 0 ..< shapeCount:
      for cell in 0 ..< size:
        let code = shapes[current * LayerWords + s * MaxN + cell]
        let x = int(code div 8)
        let y = int(code mod 8)
        for direction in 0 ..< 4:
          let nx = x + dx[direction]
          let ny = y + dy[direction]
          var occupied = false
          if nx >= 0 and nx < 8 and ny >= 0 and ny < 8:
            let neighbor = int64(nx * 8 + ny)
            for i in 0 ..< size:
              if shapes[current * LayerWords + s * MaxN + i] == neighbor: occupied = true
          if occupied: continue
          var xs, ys, candidate: array[MaxN, int64]
          for i in 0 ..< size:
            let previous = shapes[current * LayerWords + s * MaxN + i]
            xs[i] = previous div 8
            ys[i] = previous mod 8
          xs[size] = int64(nx)
          ys[size] = int64(ny)
          canonical(xs, ys, size + 1, candidate)
          var duplicate = false
          for old in 0 ..< nextCount:
            if not duplicate:
              var same = true
              for i in 0 .. size:
                if shapes[next * LayerWords + old * MaxN + i] != candidate[i]: same = false
              if same: duplicate = true
          if not duplicate:
            if nextCount >= MaxShapes: return -1
            for i in 0 .. size: shapes[next * LayerWords + nextCount * MaxN + i] = candidate[i]
            inc nextCount
    current = next
    shapeCount = nextCount
  int64(shapeCount)
