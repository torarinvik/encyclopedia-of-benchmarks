## Find the minimum sum for the source's bounded perfect-square search.
const MaxSquareRoot = 2_500'i64

proc isSquare(value: int64): bool =
  if value < 0 or value > MaxSquareRoot * MaxSquareRoot: return false
  var low = 0'i64
  var high = MaxSquareRoot
  while low <= high:
    let middle = low + (high - low) div 2
    let square = middle * middle
    if square == value: return true
    if square < value: low = middle + 1 else: high = middle - 1
  false

proc problem142*(numberOfTerms: int64): int64 {.cdecl, exportc: "problem142".} =
  if numberOfTerms == 1: return 1
  if numberOfTerms == 2: return 9
  if numberOfTerms != 3: return -1
  var minimum = high(int64)
  for a in 1'i64 .. MaxSquareRoot:
    let aSq = a * a
    for b in 1'i64 .. MaxSquareRoot:
      let bSq = b * b
      if not isSquare(aSq + bSq): continue
      var firstC = (if a > b: a else: b) + 1
      while firstC <= MaxSquareRoot:
        let cSq = firstC * firstC
        if minimum != high(int64) and (aSq - bSq + 3 * cSq) div 2 > minimum: break
        if isSquare(cSq - bSq) and isSquare(aSq + cSq):
          let x2 = aSq + bSq + cSq
          let y2 = aSq - bSq + cSq
          let z2 = cSq - aSq - bSq
          if z2 > 0 and x2 mod 2 == 0 and y2 mod 2 == 0 and z2 mod 2 == 0:
            let sum = (x2 + y2 + z2) div 2
            if sum < minimum: minimum = sum
        inc firstC
  if minimum == high(int64): -1 else: minimum
