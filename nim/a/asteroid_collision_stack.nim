const MaxN = 64
const MaxInput = 66

proc asteroid_collision_stack*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "asteroid_collision_stack".} =
  if input.isNil or length < 1 or length > csize_t(MaxInput): return -1
  let nWord = input[0]
  if nWord < 0 or nWord > MaxN.int64 or length != csize_t(nWord + 1): return -1

  var stack: array[MaxN, int8]
  var top = 0
  for i in 0 ..< int(nWord):
    let word = input[i + 1]
    if word == 0 or word < -127 or word > 127: return -1
    let incoming = int8(word)
    var alive = true
    while alive and top > 0 and stack[top - 1] > 0 and incoming < 0:
      let leftSize = int(stack[top - 1])
      let rightSize = -int(incoming)
      if leftSize < rightSize:
        dec top
      elif leftSize == rightSize:
        dec top
        alive = false
      else:
        alive = false
    if alive:
      stack[top] = incoming
      inc top

  let required = top + 1
  if output.isNil or capacity < csize_t(required): return -2
  output[0] = uint8(top)
  for i in 0 ..< top:
    output[i + 1] = cast[uint8](stack[i])
  int64(required)
