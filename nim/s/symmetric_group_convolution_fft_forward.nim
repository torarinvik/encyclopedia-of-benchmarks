## Uncompiled subgroup forward-transform draft.
import symmetric_group_convolution_fft_plan

type
  FourierBlock* = seq[int64]
  FourierBlocks* = seq[FourierBlock]

proc rankPermutation*(permutation: array[9, int], n: int): int =
  for i in 0 ..< n:
    var smaller = 0
    for j in i + 1 ..< n:
      if permutation[j] < permutation[i]: inc smaller
    result += smaller * Factorials[n - 1 - i]

proc nextPermutation*(values: var array[9, int], n: int): bool =
  if n < 2: return false
  var pivot = n - 1
  while pivot > 0 and values[pivot - 1] >= values[pivot]: dec pivot
  if pivot == 0: return false
  var successor = n - 1
  while values[successor] <= values[pivot - 1]: dec successor
  swap(values[pivot - 1], values[successor])
  var left = pivot
  var right = n - 1
  while left < right:
    swap(values[left], values[right])
    inc left
    dec right
  true

proc applyGenerator*(generator: seq[Column], source: FourierBlock, transpose: bool): FourierBlock =
  let d = generator.len
  result = newSeq[int64](d * d)
  for row, column in generator:
    if column.partner >= d: raise newException(PlanError, "invalid generator partner")
    for col in 0 ..< d:
      if transpose:
        var value = column.diagonal * source[row * d + col] mod Modulus
        if column.partner >= 0:
          value = (value + column.coefficient * source[column.partner * d + col]) mod Modulus
        result[row * d + col] = value
      else:
        let value = source[row * d + col]
        let diagonal = row * d + col
        result[diagonal] = (result[diagonal] + column.diagonal * value) mod Modulus
        if column.partner >= 0:
          let partner = column.partner * d + col
          result[partner] = (result[partner] + column.coefficient * value) mod Modulus

proc forward*(levels: Levels, n: int, input: openArray[int64]): FourierBlocks =
  if n == 1: return @[@[input[0]]]
  result = newSeq[FourierBlock](levels[n].len)
  for shape, rep in levels[n]:
    let d = rep.basis.len
    result[shape] = newSeq[int64](d * d)
  for image in 0 ..< n:
    var restricted = newSeq[int64](Factorials[n - 1])
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
      restricted[index] = input[rankPermutation(permutation, n)]
      inc index
      if not nextPermutation(h, n - 1): break
    if index != restricted.len: raise newException(PlanError, "incomplete permutations")
    let child = forward(levels, n - 1, restricted)
    for shape, rep in levels[n]:
      let d = rep.basis.len
      var embedded = newSeq[int64](d * d)
      for entry in rep.restrictions:
        if entry.child < 0 or entry.child >= child.len or entry.offset < 0 or
            entry.width < 0 or entry.offset + entry.width > d or
            child[entry.child].len != entry.width * entry.width:
          raise newException(PlanError, "invalid restriction embedding")
        for row in 0 ..< entry.width:
          for col in 0 ..< entry.width:
            embedded[(entry.offset + row) * d + entry.offset + col] =
              child[entry.child][row * entry.width + col]
      for generator in image ..< n - 1:
        embedded = applyGenerator(rep.adjacent[generator], embedded, false)
      var generator = n - 3
      while generator >= image:
        embedded = applyGenerator(rep.adjacent[generator], embedded, false)
        dec generator
      for i in 0 ..< embedded.len:
        result[shape][i] = (result[shape][i] + embedded[i]) mod Modulus
