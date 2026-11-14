## Uncompiled representation-plan draft for symmetric-group convolution.
## It is not an exported benchmark entry point.

const
  Modulus* = 998244353'i64
  Factorials* = [1, 1, 2, 6, 24, 120, 720, 5040, 40320, 362880]

type
  Shape* = array[9, uint8]
  Tableau* = array[9, uint8]
  Column* = object
    diagonal*: int64
    partner*: int                 # -1 when the column has no off-diagonal entry
    coefficient*: int64
  Embedding* = object
    child*, offset*, width*: int
  Representation* = object
    shape*: Shape
    basis*: seq[Tableau]
    adjacent*: seq[seq[Column]]
    restrictions*: seq[Embedding]
  Levels* = seq[seq[Representation]]
  PlanError* = object of CatchableError

proc power*(baseValue, exponentValue: int64): int64 =
  var base = baseValue
  var exponent = exponentValue
  result = 1
  while exponent > 0:
    if (exponent and 1) != 0: result = result * base mod Modulus
    base = base * base mod Modulus
    exponent = exponent shr 1

proc enumerate(degree, next: int, shape: var Shape, tableau: var Tableau,
               bases: var seq[Representation]) =
  if next == degree:
    var found = -1
    for index in 0 ..< bases.len:
      if bases[index].shape == shape:
        found = index
        break
    if found < 0:
      bases.add(Representation(shape: shape))
      found = bases.high
    bases[found].basis.add(tableau)
    return
  for row in 0 ..< degree:
    if row > 0 and shape[row] >= shape[row - 1]: continue
    let column = shape[row]
    tableau[next] = uint8(row * 9 + int(column))
    inc shape[row]
    enumerate(degree, next + 1, shape, tableau, bases)
    dec shape[row]
    if column == 0: break

proc shapeCompare(a, b: Shape): int =
  for i in 0 ..< 9:
    if a[i] < b[i]: return -1
    if a[i] > b[i]: return 1
  0

proc tableauCompare(a, b: Tableau, degree: int): int =
  var i = degree
  while i > 0:
    dec i
    if a[i] < b[i]: return -1
    if a[i] > b[i]: return 1
  0

proc representationPlan(degree: int): seq[Representation] =
  var shape: Shape
  var tableau: Tableau
  enumerate(degree, 0, shape, tableau, result)
  for i in 1 ..< result.len:
    var j = i
    while j > 0 and shapeCompare(result[j - 1].shape, result[j].shape) > 0:
      swap(result[j - 1], result[j])
      dec j
  for rep in result.mitems:
    for i in 1 ..< rep.basis.len:
      var j = i
      while j > 0 and tableauCompare(rep.basis[j - 1], rep.basis[j], degree) > 0:
        swap(rep.basis[j - 1], rep.basis[j])
        dec j
    rep.adjacent = newSeq[seq[Column]](degree - 1)
    for label in 0 ..< degree - 1:
      rep.adjacent[label] = newSeq[Column](rep.basis.len)
      for index, entry in rep.basis:
        let first = int(entry[label])
        let second = int(entry[label + 1])
        let distance = second mod 9 - second div 9 - first mod 9 + first div 9
        if distance == 0: raise newException(PlanError, "equal adjacent contents")
        let diagonal = power((int64(distance) + Modulus) mod Modulus, Modulus - 2)
        var column = Column(diagonal: diagonal, partner: -1)
        if abs(distance) != 1:
          var exchanged = entry
          swap(exchanged[label], exchanged[label + 1])
          var lo = 0
          var hi = rep.basis.len
          while lo < hi:
            let mid = lo + (hi - lo) div 2
            if tableauCompare(rep.basis[mid], exchanged, degree) < 0: lo = mid + 1
            else: hi = mid
          if lo == rep.basis.len or tableauCompare(rep.basis[lo], exchanged, degree) != 0:
            raise newException(PlanError, "missing exchanged tableau")
          column.partner = lo
          column.coefficient = if distance > 0: 1'i64
            else: (1 - diagonal * diagonal mod Modulus + Modulus) mod Modulus
        rep.adjacent[label][index] = column

proc makeLevels*(degree: int): Levels =
  if degree < 1 or degree > 9: raise newException(PlanError, "invalid degree")
  result = newSeq[seq[Representation]](degree + 1)
  for n in 1 .. degree: result[n] = representationPlan(n)
  for n in 2 .. degree:
    for parent in result[n].mitems:
      var start = 0
      while start < parent.basis.len:
        let corner = int(parent.basis[start][n - 1])
        var stop = start + 1
        while stop < parent.basis.len and int(parent.basis[stop][n - 1]) == corner: inc stop
        var childShape = parent.shape
        let row = corner div 9
        if row >= 9 or childShape[row] == 0:
          raise newException(PlanError, "invalid restriction corner")
        dec childShape[row]
        var child = -1
        for i in 0 ..< result[n - 1].len:
          if result[n - 1][i].shape == childShape:
            child = i
            break
        if child < 0 or result[n - 1][child].basis.len != stop - start:
          raise newException(PlanError, "missing restriction block")
        for i in 0 ..< stop - start:
          for label in 0 ..< n - 1:
            if parent.basis[start + i][label] != result[n - 1][child].basis[i][label]:
              raise newException(PlanError, "restriction ordering differs")
        parent.restrictions.add(Embedding(child: child, offset: start, width: stop - start))
        start = stop
