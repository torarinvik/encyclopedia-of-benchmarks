## Uncompiled inverse transform using the transposed subgroup recurrence.
import symmetric_group_convolution_fft_plan
import symmetric_group_convolution_fft_forward

proc invariantDiagonal(rep: Representation): seq[int64] =
  let d = rep.basis.len
  result = newSeq[int64](d)
  for weight in result.mitems: weight = -1
  var queue = newSeq[int](d)
  for start in 0 ..< d:
    if result[start] != -1: continue
    result[start] = 1
    var head = 0
    var tail = 1
    queue[0] = start
    while head < tail:
      let source = queue[head]
      inc head
      for generator in rep.adjacent:
        let edge = generator[source]
        if edge.partner < 0: continue
        if edge.partner >= d: raise newException(PlanError, "invalid generator edge")
        let back = generator[edge.partner]
        if back.partner != source or edge.coefficient == 0 or back.coefficient == 0:
          raise newException(PlanError, "invalid generator pair")
        var candidate = result[source] * back.coefficient mod Modulus
        candidate = candidate * power(edge.coefficient, Modulus - 2) mod Modulus
        if result[edge.partner] == -1:
          if tail >= d: raise newException(PlanError, "invalid generator graph")
          result[edge.partner] = candidate
          queue[tail] = edge.partner
          inc tail
        elif result[edge.partner] != candidate:
          raise newException(PlanError, "inconsistent invariant diagonal")

proc transposeForward(levels: Levels, n: int, gradients: FourierBlocks): seq[int64] =
  if n == 1: return @[gradients[0][0]]
  result = newSeq[int64](Factorials[n])
  for image in 0 ..< n:
    var child = newSeq[FourierBlock](levels[n - 1].len)
    for shape, rep in levels[n - 1]:
      child[shape] = newSeq[int64](rep.basis.len * rep.basis.len)
    for shape, rep in levels[n]:
      let d = rep.basis.len
      if gradients[shape].len != d * d:
        raise newException(PlanError, "invalid gradient block")
      var current = newSeq[int64](d * d)
      for i in 0 ..< current.len: current[i] = gradients[shape][i]
      for generator in image ..< n - 1:
        current = applyGenerator(rep.adjacent[generator], current, true)
      var generator = n - 3
      while generator >= image:
        current = applyGenerator(rep.adjacent[generator], current, true)
        dec generator
      for entry in rep.restrictions:
        if entry.child < 0 or entry.child >= child.len or entry.offset < 0 or
            entry.width < 0 or entry.offset + entry.width > d or
            child[entry.child].len != entry.width * entry.width:
          raise newException(PlanError, "invalid restriction embedding")
        for row in 0 ..< entry.width:
          for col in 0 ..< entry.width:
            let target = row * entry.width + col
            child[entry.child][target] = (child[entry.child][target] +
              current[(entry.offset + row) * d + entry.offset + col]) mod Modulus
    let restricted = transposeForward(levels, n - 1, child)
    var h: array[9, int]
    for i in 0 ..< n - 1: h[i] = i
    var index = 0
    while true:
      var permutation = h
      permutation[n - 1] = n - 1
      for i in 0 ..< n:
        if permutation[i] == image: permutation[i] = n - 1
        elif permutation[i] == n - 1: permutation[i] = image
      if index >= restricted.len: raise newException(PlanError, "too many permutations")
      result[rankPermutation(permutation, n)] = restricted[index]
      inc index
      if not nextPermutation(h, n - 1): break
    if index != restricted.len: raise newException(PlanError, "incomplete permutations")

proc inverse*(levels: Levels, n: int, blocks: FourierBlocks): seq[int64] =
  if n == 1: return @[blocks[0][0]]
  let inverseOrder = power(int64(Factorials[n]), Modulus - 2)
  var weighted = newSeq[FourierBlock](levels[n].len)
  for shape, rep in levels[n]:
    let d = rep.basis.len
    if blocks[shape].len != d * d: raise newException(PlanError, "invalid Fourier block")
    let diagonal = invariantDiagonal(rep)
    var inverseDiagonal = newSeq[int64](d)
    for i in 0 ..< d: inverseDiagonal[i] = power(diagonal[i], Modulus - 2)
    weighted[shape] = newSeq[int64](d * d)
    for row in 0 ..< d:
      for col in 0 ..< d:
        var value = blocks[shape][row * d + col] * int64(d) mod Modulus
        value = value * inverseOrder mod Modulus
        value = value * diagonal[row] mod Modulus
        weighted[shape][row * d + col] = value * inverseDiagonal[col] mod Modulus
  transposeForward(levels, n, weighted)
