const MaxTextLength = 128
proc decimalDigits(valueInput: int): int =
  var value = valueInput
  result = 1
  while value >= 10: value = value div 10; inc result

## Generate the next look-and-say string from bounded ASCII input.
proc conway*(input: ptr UncheckedArray[int64], length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "conway".} =
  if input == nil or length < 2 or length > csize_t(MaxTextLength + 1): return -1
  let n = input[0]
  if n < 1 or n > MaxTextLength or length != csize_t(n + 1): return -1
  for i in 0 ..< int(n):
    if input[i + 1] < 0 or input[i + 1] > 127: return -1
  var needed = 0
  var i = 0
  while i < int(n):
    var j = i + 1
    while j < int(n) and (input[j] == input[j + 1] or input[j] == 10 or input[j] == 13): inc j
    needed += decimalDigits(j - i) + 1
    i = j
  if output == nil or capacity < csize_t(needed): return -2
  var pos = 0
  i = 0
  while i < int(n):
    var j = i + 1
    while j < int(n) and (input[j] == input[j + 1] or input[j] == 10 or input[j] == 13): inc j
    var run = j - i
    let start = pos
    while true:
      output[pos] = uint8(48 + run mod 10); inc pos
      run = run div 10
      if run == 0: break
    var left = start
    var right = pos - 1
    while left < right:
      swap(output[left], output[right]); inc left; dec right
    output[pos] = uint8(input[i + 1]); inc pos
    i = j
  int64(pos)
