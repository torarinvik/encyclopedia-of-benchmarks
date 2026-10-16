const MaxPeople = 64

proc celebrity_finder*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "celebrity_finder".} =
  if input.isNil or length < csize_t(2): return -2
  let nValue = input[0]
  if nValue < 1 or nValue > MaxPeople: return -2
  let n = int(nValue)
  if int(length) != 1 + n * n: return -2
  for i in 1 ..< int(length):
    if input[i] != 0 and input[i] != 1: return -2
  var stack: array[MaxPeople, int]
  var top = 0
  for i in 0 ..< n:
    stack[top] = i
    inc top
  while top > 1:
    dec top
    let person1 = stack[top]
    dec top
    let person2 = stack[top]
    if input[1 + person1 * n + person2] == 1: stack[top] = person2
    else: stack[top] = person1
    inc top
  let candidate = stack[0]
  for i in 0 ..< n:
    if i != candidate and (input[1 + candidate * n + i] == 1 or input[1 + i * n + candidate] == 0): return -1
  int64(candidate)
