const PRIME_LIMIT = 1_000_000
const PRIME = 1'u8
const FILTERED_PRIME = 2'u8
const FILTERED_CHECKED = 3'u8
const CHECKED_NONPRIME = 4'u8
const CHECKED_OTHER_PRIME = 5'u8
type StateArray = array[PRIME_LIMIT, uint8]

proc repeatedExtraDigits(value: int64): int =
  var counts: array[10, int]
  var length = 0
  var remaining = value
  while remaining > 0:
    inc counts[int(remaining mod 10)]
    inc length
    remaining = remaining div 10
  var distinct = 0
  for count in counts:
    if count > 0: inc distinct
  length - distinct

proc countDigit(value: int64, digit: int64): int =
  var remaining = value
  while remaining > 0:
    if remaining mod 10 == digit: inc result
    remaining = remaining div 10

proc replaceAll(value: int64, digit: int64, replacement: int64): int64 =
  result = value
  var remaining = value
  var place = 1'i64
  while remaining > 0:
    if remaining mod 10 == digit: result += (replacement - digit) * place
    remaining = remaining div 10
    place *= 10

proc markChecked(state: var StateArray, value: int64) =
  let index = int(value)
  if state[index] == FILTERED_PRIME: state[index] = FILTERED_CHECKED
  elif state[index] == 0: state[index] = CHECKED_NONPRIME
  elif state[index] == PRIME: state[index] = CHECKED_OTHER_PRIME

proc problem51*(ignored: int64): int64 {.cdecl, exportc: "problem51".} =
  if ignored != 0: return -1
  var state: StateArray
  for value in 2 ..< PRIME_LIMIT: state[value] = PRIME
  for prime in 2 ..< PRIME_LIMIT:
    if prime * prime >= PRIME_LIMIT: break
    if state[prime] != PRIME: continue
    var multiple = prime * prime
    while multiple < PRIME_LIMIT:
      state[multiple] = 0
      multiple += prime
  for value in 2 ..< PRIME_LIMIT:
    if state[value] == PRIME and repeatedExtraDigits(int64(value)) >= 3:
      state[value] = FILTERED_PRIME

  for number in 2 ..< PRIME_LIMIT:
    if state[number] != FILTERED_PRIME: continue
    var place = 1'i64
    while int64(number) div place >= 10: place *= 10
    var seenDigits: array[10, bool]
    while place > 0:
      let digit = (int64(number) div place) mod 10
      let digitIndex = int(digit)
      if not seenDigits[digitIndex] and countDigit(int64(number), digit) >= 2:
        seenDigits[digitIndex] = true
        var familyCount = 0
        var familyMinimum = high(int64)
        for replacement in 0'i64 .. 9'i64:
          let member = replaceAll(int64(number), digit, replacement)
          markChecked(state, member)
          let memberState = state[int(member)]
          if memberState == FILTERED_PRIME or memberState == FILTERED_CHECKED:
            inc familyCount
            if member < familyMinimum: familyMinimum = member
        if familyCount == 8: return familyMinimum
      place = place div 10
  -1
