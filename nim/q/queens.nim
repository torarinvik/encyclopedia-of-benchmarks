const
  MaxN = 14
  MaxDiags = 2 * MaxN - 1
  EmptyOwner = 101
  MaxOutputBytes = 80

type
  QueensState = object
    n: int
    queen: array[MaxN, int]
    file: array[MaxN, int]
    forwardDiag: array[MaxDiags, int]
    backwardDiag: array[MaxDiags, int]
    solutions: uint64

proc findSolutions(state: var QueensState, level: int) =
  if level == state.n:
    inc state.solutions
    return
  for fileIndex in 0 ..< state.n:
    let forward = fileIndex + level
    let backward = level - fileIndex + state.n - 1
    if state.file[fileIndex] >= level and state.forwardDiag[forward] >= level and
        state.backwardDiag[backward] >= level:
      state.queen[level] = fileIndex
      state.file[fileIndex] = level
      state.forwardDiag[forward] = level
      state.backwardDiag[backward] = level
      findSolutions(state, level + 1)
      state.file[fileIndex] = EmptyOwner
      state.forwardDiag[forward] = EmptyOwner
      state.backwardDiag[backward] = EmptyOwner

proc appendText(output: ptr UncheckedArray[uint8], position: var int, text: string) =
  for character in text:
    output[position] = uint8(ord(character))
    inc position

proc appendUnsigned(output: ptr UncheckedArray[uint8], position: var int, valueInput: uint64) =
  var reversed: array[24, uint8]
  var count = 0
  var value = valueInput
  while true:
    reversed[count] = uint8(48'u64 + value mod 10'u64)
    inc count
    value = value div 10'u64
    if value == 0'u64: break
  while count > 0:
    dec count
    output[position] = reversed[count]
    inc position

proc renderOutput(n: int, solutions: uint64,
                  output: ptr UncheckedArray[uint8]): int =
  result = 0
  appendUnsigned(output, result, uint64(n))
  if n == 1:
    appendText(output, result, " queen on a ")
  else:
    appendText(output, result, " queens on a ")
  appendUnsigned(output, result, uint64(n))
  output[result] = uint8(ord('x'))
  inc result
  appendUnsigned(output, result, uint64(n))
  appendText(output, result, " board...\n")
  if solutions == 1'u64:
    appendText(output, result, "...there is 1 solution\n")
  else:
    appendText(output, result, "...there are ")
    appendUnsigned(output, result, solutions)
    appendText(output, result, " solutions\n")

proc queens*(n: int64, output: ptr UncheckedArray[uint8],
             outputCapacity: csize_t): int64 {.cdecl, exportc: "queens".} =
  if n < 1 or n > int64(MaxN): return -1
  var state: QueensState
  state.n = int(n)
  for index in 0 ..< MaxN: state.file[index] = EmptyOwner
  for index in 0 ..< MaxDiags:
    state.forwardDiag[index] = EmptyOwner
    state.backwardDiag[index] = EmptyOwner
  findSolutions(state, 0)

  var formatted: array[MaxOutputBytes, uint8]
  let buffer = cast[ptr UncheckedArray[uint8]](addr formatted[0])
  let required = renderOutput(state.n, state.solutions, buffer)
  if output.isNil or outputCapacity < csize_t(required): return -2
  for index in 0 ..< required: output[index] = formatted[index]
  int64(required)
