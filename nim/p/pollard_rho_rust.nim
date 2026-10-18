const MaxNum = 1_000_000_000'i64
const U32Mod = 4_294_967_296'i64
const Batch = 32'i64
const Cutoff = 262_144'i64

proc gcdNonnegative(leftValue, rightValue: int64): int64 =
  var left = leftValue
  var right = rightValue
  while left != 0:
    let remainder = right mod left
    right = left
    left = remainder
  right

proc modPower(baseValue, powerValue, modulus: int64): int64 =
  var base = baseValue mod modulus
  var power = powerValue
  if base == 0: return 0
  var result = 1'i64
  while power > 0:
    if power mod 2 != 0: result = result * base mod modulus
    base = base * base mod modulus
    power = power div 2
  result

proc passesBase(number, base: int64): bool =
  var oddPower = number - 1
  var twoPower = 0'i64
  while oddPower mod 2 == 0:
    oddPower = oddPower div 2
    inc twoPower
  var value = modPower(base, oddPower, number)
  if value == 1 or value == number - 1: return true
  for _ in 1'i64 ..< twoPower:
    value = value * value mod number
    if value == number - 1: return true
  false

proc probablePrime(number: int64): bool =
  if number <= 4: return number == 2 or number == 3
  if number == 5 or number == 7: return true
  passesBase(number, 2) and passesBase(number, 3) and passesBase(number, 5) and passesBase(number, 7)

proc advance(x, c, number: int64): int64 =
  (x * x + c) mod number

proc brentFactor(number, x0, c: int64): int64 =
  var x = x0
  var xStart = 0'i64
  var y = 0'i64
  var remainder = 1'i64
  var currentGcd = 1'i64
  var maxIterations = 1'i64
  while currentGcd == 1:
    y = x
    for _ in 1'i64 ..< maxIterations: x = advance(x, c, number)
    var bigIteration = 0'i64
    while bigIteration < maxIterations and currentGcd == 1:
      xStart = x
      var smallIteration = 0'i64
      while smallIteration < Batch and smallIteration < maxIterations - bigIteration:
        inc smallIteration
        x = advance(x, c, number)
        remainder = remainder * abs(x - y) mod number
      currentGcd = gcdNonnegative(remainder, number)
      bigIteration += Batch
    maxIterations *= 2
    if maxIterations > Cutoff: break
  if currentGcd == number:
    while currentGcd == 1:
      xStart = advance(xStart, c, number)
      currentGcd = gcdNonnegative(abs(xStart - y), number)
  currentGcd

proc pollardRhoRust*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "pollard_rho_rust".} =
  if input == nil or length != 3: return -1
  let number = input[0]
  var state = input[1]
  let restartLimit = input[2]
  if number < 2 or number > MaxNum or state < 0 or state >= U32Mod or restartLimit < 1 or restartLimit > 16: return -1
  if probablePrime(number): return number

  for _ in 0'i64 ..< restartLimit:
    state = (1_103_515_245'i64 * state + 12_345) mod U32Mod
    let highX = state
    state = (1_103_515_245'i64 * state + 12_345) mod U32Mod
    let lowX = state
    let xMod = number - 3
    let x0 = ((highX mod xMod) * (U32Mod mod xMod) + lowX mod xMod) mod xMod + 2
    state = (1_103_515_245'i64 * state + 12_345) mod U32Mod
    let highC = state
    state = (1_103_515_245'i64 * state + 12_345) mod U32Mod
    let lowC = state
    let cMod = number - 2
    let c = ((highC mod cMod) * (U32Mod mod cMod) + lowC mod cMod) mod cMod + 1
    let factor = brentFactor(number, x0, c)
    if factor != 1 and factor != number: return factor
  0
