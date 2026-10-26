## Clean-room bounded YACR2 Maze1 profile; rights status is documented in package README.
const MaxColumns = 16
const MaxTracks = 16

proc freeVertical(v: ptr UncheckedArray[int64], plane, columns, x, y1, y2: int): bool =
  let low = min(y1, y2)
  let high = max(y1, y2)
  for y in low .. high:
    if v[plane + y * columns + x - 1] != 0: return false
  true

proc freeHorizontal(v: ptr UncheckedArray[int64], plane, columns, x1, x2, y: int): bool =
  let low = min(x1, x2)
  let high = max(x1, x2)
  for x in low .. high:
    if v[plane + y * columns + x - 1] != 0: return false
  true

proc tryDogleg(v: ptr UncheckedArray[int64], plane, vcv, columns, tracks, column,
               bottom, top, dx: int, upper: bool): bool =
  let neighbor = column + dx
  if upper:
    let jog = bottom - 1
    return freeVertical(v, plane, columns, column, tracks + 1, bottom) and
      freeVertical(v, plane, columns, column, 0, jog) and
      freeHorizontal(v, plane, columns, column, neighbor, jog) and
      freeVertical(v, plane, columns, neighbor, jog, top) and v[vcv + neighbor - 1] == 0
  let jog = top + 1
  freeVertical(v, plane, columns, column, 0, top) and
    freeVertical(v, plane, columns, column, tracks + 1, jog) and
    freeHorizontal(v, plane, columns, column, neighbor, jog) and
    freeVertical(v, plane, columns, neighbor, jog, bottom) and v[vcv + neighbor - 1] == 0

proc ptrdist_yacr2_maze1_dogleg*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "ptrdist_yacr2_maze1_dogleg".} =
  if input.isNil or length < csize_t(5): return -1
  if input[0] < 2 or input[0] > MaxColumns or input[1] < 2 or input[1] > MaxTracks: return -1
  let columns = int(input[0]); let tracks = int(input[1])
  if input[2] < 1 or input[2] > input[0] or input[3] < 1 or input[3] >= input[4] or input[4] > input[1]: return -1
  let column = int(input[2]); let bottom = int(input[3]); let top = int(input[4])
  if length != csize_t(5 + columns + columns * (tracks + 2)): return -1
  let vcv = 5; let plane = vcv + columns
  for i in vcv ..< plane:
    if input[i] != 0 and input[i] != 1: return -1
  for i in plane ..< int(length):
    if input[i] != 0 and input[i] != 1: return -1

  if bottom > 1 and column > 1 and tryDogleg(input, plane, vcv, columns, tracks, column, bottom, top, -1, true): return 1
  if bottom > 1 and column < columns and tryDogleg(input, plane, vcv, columns, tracks, column, bottom, top, 1, true): return 2
  if top < tracks and column > 1 and tryDogleg(input, plane, vcv, columns, tracks, column, bottom, top, -1, false): return 3
  if top < tracks and column < columns and tryDogleg(input, plane, vcv, columns, tracks, column, bottom, top, 1, false): return 4
  0
