type I64Input = ptr UncheckedArray[int64]

func kaprekarStep(number: int64): int64 =
  var d0 = number div 1000
  var d1 = (number div 100) mod 10
  var d2 = (number div 10) mod 10
  var d3 = number mod 10
  var temp = 0'i64

  if d0 > d1:
    temp = d0
    d0 = d1
    d1 = temp
  if d2 > d3:
    temp = d2
    d2 = d3
    d3 = temp
  if d0 > d2:
    temp = d0
    d0 = d2
    d2 = temp
  if d1 > d3:
    temp = d1
    d1 = d3
    d3 = temp
  if d1 > d2:
    temp = d1
    d1 = d2
    d2 = temp

  let ascending = d0 * 1000 + d1 * 100 + d2 * 10 + d3
  let descending = d3 * 1000 + d2 * 100 + d1 * 10 + d0
  descending - ascending

proc kaprekar_constant*(values: I64Input, length: csize_t): int64 {.cdecl, exportc: "kaprekar_constant".} =
  if values == nil or length != 2: return -1
  let number = values[0]
  let maxIterations = values[1]
  if number < 0 or number > 9999 or maxIterations < 1 or maxIterations > 16: return -1
  if number == 6174: return 0

  var current = number
  for iteration in 1'i64 .. maxIterations:
    current = kaprekarStep(current)
    if current == 6174: return iteration
    if current == 0: return -1
  -1
