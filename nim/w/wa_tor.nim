const
  MaxWidth = 8
  MaxHeight = 8
  MaxCells = 64
  MaxChronons = 32
  MaxEntityRecords = MaxCells * (MaxChronons + 1)
  HashModulus = 2_147_483_647'i64
  HashMultiplier = 1_000_003'i64

type Entity = object
  kind: int
  row: int
  col: int
  timer: int
  energy: int
  alive: bool

proc breedTime(kind: int): int =
  if kind == 1: 5 else: 20

proc moveAndReproduce(entities: var array[MaxEntityRecords, Entity], entityCount: var int,
                      board: var array[MaxCells, int], entityId, width, height: int) =
  let oldRow = entities[entityId].row
  let oldCol = entities[entityId].col
  let deltaRows = [-1, 0, 1, 0] # N, E, S, W
  let deltaCols = [0, 1, 0, -1]
  var moved = false
  for direction in 0 ..< 4:
    let row = oldRow + deltaRows[direction]
    let col = oldCol + deltaCols[direction]
    if row < 0 or row >= height or col < 0 or col >= width: continue
    let destination = row * width + col
    if board[destination] != -1: continue
    board[oldRow * width + oldCol] = -1
    board[destination] = entityId
    entities[entityId].row = row
    entities[entityId].col = col
    moved = true
    break
  if moved and entities[entityId].timer <= 0:
    if entityCount < MaxEntityRecords:
      let childId = entityCount
      let kind = entities[entityId].kind
      let timer = breedTime(kind)
      entities[childId] = Entity(kind: kind, row: oldRow, col: oldCol, timer: timer,
                                  energy: (if kind == 1: 0 else: 15), alive: true)
      board[oldRow * width + oldCol] = childId
      entities[entityId].timer = timer
      inc entityCount
  else:
    dec entities[entityId].timer

proc predatorAction(entities: var array[MaxEntityRecords, Entity], entityCount: var int,
                    board: var array[MaxCells, int], entityId, width, height: int) =
  let current = entities[entityId].row * width + entities[entityId].col
  if entities[entityId].energy == 0:
    board[current] = -1
    entities[entityId].alive = false
    return
  let deltaRows = [-1, 1, 0, 0] # N, S, W, E
  let deltaCols = [0, 0, -1, 1]
  var target = -1
  for direction in 0 ..< 4:
    let row = entities[entityId].row + deltaRows[direction]
    let col = entities[entityId].col + deltaCols[direction]
    if row < 0 or row >= height or col < 0 or col >= width: continue
    let cell = row * width + col
    let occupant = board[cell]
    if occupant != -1 and entities[occupant].kind == 1:
      target = cell
      break
  if target != -1:
    let preyId = board[target]
    entities[preyId].alive = false
    board[current] = -1
    board[target] = entityId
    entities[entityId].row = target div width
    entities[entityId].col = target mod width
    entities[entityId].energy += 5
  else:
    moveAndReproduce(entities, entityCount, board, entityId, width, height)
  dec entities[entityId].energy

proc wa_tor*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "wa_tor".} =
  if values.isNil or length < 3 or length > 196: return -1
  if values[0] < 1 or values[0] > MaxWidth or values[1] < 1 or values[1] > MaxHeight or
      values[2] < 0 or values[2] > MaxChronons: return -1
  let width = int(values[0])
  let height = int(values[1])
  let chronons = int(values[2])
  let cellCount = width * height
  if length != csize_t(3 + 3 * cellCount): return -1

  var entities: array[MaxEntityRecords, Entity]
  var entityCount = 0
  var board: array[MaxCells, int]
  var snapshot: array[MaxCells, int]
  for cell in 0 ..< cellCount: board[cell] = -1
  for cell in 0 ..< cellCount:
    let kindValue = values[3 + 3 * cell]
    let timerValue = values[4 + 3 * cell]
    let energyValue = values[5 + 3 * cell]
    if kindValue == 0:
      if timerValue != 0 or energyValue != 0: return -1
      continue
    if kindValue == 1:
      if timerValue < 0 or timerValue > 5 or energyValue != 0: return -1
    elif kindValue == 2:
      if timerValue < 0 or timerValue > 20 or energyValue < 0 or energyValue > 15: return -1
    else:
      return -1
    let entityId = entityCount
    entities[entityId] = Entity(kind: int(kindValue), row: cell div width, col: cell mod width,
                                timer: int(timerValue), energy: int(energyValue), alive: true)
    board[cell] = entityId
    inc entityCount

  for chronon in 0 ..< chronons:
    var snapshotCount = 0
    for cell in 0 ..< cellCount:
      if board[cell] != -1:
        snapshot[snapshotCount] = board[cell]
        inc snapshotCount
    for i in 0 ..< snapshotCount:
      let entityId = snapshot[i]
      if not entities[entityId].alive: continue
      if entities[entityId].kind == 1:
        moveAndReproduce(entities, entityCount, board, entityId, width, height)
      else:
        predatorAction(entities, entityCount, board, entityId, width, height)

  var preyCount = 0'i64
  var predatorCount = 0'i64
  var stateHash = 0'i64
  for cell in 0 ..< cellCount:
    var code = 0'i64
    if board[cell] != -1:
      let entity = entities[board[cell]]
      if entity.kind == 1:
        inc preyCount
        code = int64(entity.timer + 33)
      else:
        inc predatorCount
        code = 1000 + 53 * int64(entity.energy) + int64(entity.timer) + 32
    stateHash = (stateHash * HashMultiplier + code) mod HashModulus
  stateHash * 4225 + 65 * preyCount + predatorCount
