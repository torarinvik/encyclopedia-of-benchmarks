const DiskCount = 14'i32
const MaxCells = 18'i32
const MaxRuns = 100'i64
const MaxOutputBytes = 600
const StagingBytes = 2400

type
  Cell = object
    discSize: int32
    next: int32
  TowerState = object
    stack: array[4, int32]
    cells: array[MaxCells + 1, Cell]
    freeList: int32
    movesDone: int32

proc getElement(state: var TowerState): int32 =
  if state.freeList <= 0: return 0
  let element = state.freeList
  state.freeList = state.cells[int(element)].next
  element

proc push(state: var TowerState, discSize: int32, peg: int) =
  if state.stack[peg] > 0 and state.cells[int(state.stack[peg])].discSize <= discSize: return
  let element = getElement(state)
  if element <= 0: return
  state.cells[int(element)].next = state.stack[peg]
  state.stack[peg] = element
  state.cells[int(element)].discSize = discSize

proc initializePeg(state: var TowerState, peg: int, disks: int32) =
  state.stack[peg] = 0
  var disk = disks
  while disk >= 1:
    push(state, disk, peg)
    dec disk

proc pop(state: var TowerState, peg: int): int32 =
  if state.stack[peg] <= 0: return 0
  let element = state.stack[peg]
  let discSize = state.cells[int(element)].discSize
  state.stack[peg] = state.cells[int(element)].next
  state.cells[int(element)].next = state.freeList
  state.freeList = element
  discSize

proc doMove(state: var TowerState, source, destination: int) =
  let discSize = pop(state, source)
  push(state, discSize, destination)
  inc state.movesDone

proc tower(state: var TowerState, source, destination: int, disks: int32) =
  if disks == 1:
    doMove(state, source, destination)
  else:
    let auxiliary = 6 - source - destination
    tower(state, source, auxiliary, disks - 1)
    doMove(state, source, destination)
    tower(state, auxiliary, destination, disks - 1)

proc runTowers(): int32 =
  var state = default(TowerState)
  for index in 1 .. int(MaxCells): state.cells[index].next = int32(index - 1)
  state.freeList = MaxCells
  initializePeg(state, 1, DiskCount)
  state.stack[2] = 0
  state.stack[3] = 0
  state.movesDone = 0
  tower(state, 1, 2, DiskCount)
  state.movesDone

proc appendText(buffer: var array[StagingBytes, uint8], used: var int, text: string) =
  for ch in text:
    buffer[used] = uint8(ord(ch))
    inc used

proc appendInteger(buffer: var array[StagingBytes, uint8], used: var int, value: int32) =
  var remaining = value
  if remaining < 0:
    buffer[used] = uint8(ord('-'))
    inc used
    remaining = -remaining
  var reverse: array[12, uint8]
  var count = 0
  while true:
    reverse[count] = uint8(48 + remaining mod 10)
    inc count
    remaining = remaining div 10
    if remaining == 0: break
  while count > 0:
    dec count
    buffer[used] = reverse[count]
    inc used

proc stanford_towers*(runs: int64, output: ptr UncheckedArray[uint8],
    outputCapacity: csize_t): int64 {.cdecl, exportc: "stanford_towers".} =
  if runs < 1 or runs > MaxRuns: return -1
  if output.isNil: return -2
  var staged: array[StagingBytes, uint8]
  var used = 0
  for _ in 0 ..< int(runs):
    let movesDone = runTowers()
    if movesDone != 16383: appendText(staged, used, " Error in Towers.\n")
    appendInteger(staged, used, movesDone)
    appendText(staged, used, "\n")
  if used > MaxOutputBytes or outputCapacity < csize_t(used): return -2
  for index in 0 ..< used: output[index] = staged[index]
  int64(used)
