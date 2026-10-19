const MaxN = 10'i64
const MaxOutputBytes = 89

proc ackermannValue(x, y: int64): int64 =
  if x == 0: return y + 1
  ackermannValue(x - 1, if y == 0: 1'i64 else: ackermannValue(x, y - 1))

proc fibonacciInteger(n: int64): int64 =
  if n < 2: return 1
  fibonacciInteger(n - 2) + fibonacciInteger(n - 1)

proc fibonacciFloat(n: float64): float64 =
  if n < 2.0: return 1.0
  fibonacciFloat(n - 2.0) + fibonacciFloat(n - 1.0)

proc takeuchiInteger(x, y, z: int64): int64 =
  if y < x:
    return takeuchiInteger(takeuchiInteger(x - 1, y, z),
                           takeuchiInteger(y - 1, z, x),
                           takeuchiInteger(z - 1, x, y))
  z

proc takeuchiFloat(x, y, z: float64): float64 =
  if y < x:
    return takeuchiFloat(takeuchiFloat(x - 1.0, y, z),
                          takeuchiFloat(y - 1.0, z, x),
                          takeuchiFloat(z - 1.0, x, y))
  z

proc appendText(buffer: var array[MaxOutputBytes, uint8], used: var int, text: string) =
  for ch in text:
    buffer[used] = uint8(ord(ch))
    inc used

proc appendNumber(buffer: var array[MaxOutputBytes, uint8], used: var int, value: int64) =
  var reversed: array[20, uint8]
  var remaining = value
  var count = 0
  while true:
    reversed[count] = uint8(48'i64 + remaining mod 10)
    inc count
    remaining = remaining div 10
    if remaining == 0: break
  while count > 0:
    dec count
    buffer[used] = reversed[count]
    inc used

proc benchmarkgame_recursive*(n: int64, output: ptr UncheckedArray[uint8],
    outputCapacity: csize_t): int64 {.cdecl, exportc: "benchmarkgame_recursive".} =
  if n < 0 or n > MaxN: return -1
  if output.isNil: return -2

  var staged: array[MaxOutputBytes, uint8]
  var used = 0
  appendText(staged, used, "Ack(3,")
  appendNumber(staged, used, n + 1)
  appendText(staged, used, "): ")
  appendNumber(staged, used, ackermannValue(3, n + 1))
  appendText(staged, used, "\nFib(")
  appendNumber(staged, used, 28 + n)
  appendText(staged, used, ".0): ")
  appendNumber(staged, used, int64(fibonacciFloat(float64(28 + n))))
  appendText(staged, used, ".0\nTak(")
  appendNumber(staged, used, 3 * n)
  appendText(staged, used, ",")
  appendNumber(staged, used, 2 * n)
  appendText(staged, used, ",")
  appendNumber(staged, used, n)
  appendText(staged, used, "): ")
  appendNumber(staged, used, takeuchiInteger(3 * n, 2 * n, n))
  appendText(staged, used, "\nFib(3): ")
  appendNumber(staged, used, fibonacciInteger(3))
  appendText(staged, used, "\nTak(3.0,2.0,1.0): ")
  appendNumber(staged, used, int64(takeuchiFloat(3.0, 2.0, 1.0)))
  appendText(staged, used, ".0\n")

  if outputCapacity < csize_t(used): return -2
  for index in 0 ..< used: output[index] = staged[index]
  int64(used)
