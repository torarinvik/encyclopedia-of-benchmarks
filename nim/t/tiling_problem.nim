const MaxSize = 16
proc fill(board: var array[256, int32], width, row, col, mr, mc: int, tile: var int32) =
  if width == 1: return
  let h = width div 2
  let t = tile; inc tile
  let qr = [row, row, row+h, row+h]
  let qc = [col, col+h, col, col+h]
  let cr = [row+h-1, row+h-1, row+h, row+h]
  let cc = [col+h-1, col+h, col+h-1, col+h]
  let missing = if mr < row+h: (if mc < col+h: 0 else: 1) else: (if mc < col+h: 2 else: 3)
  for q in 0 ..< 4:
    var nr = mr; var nc = mc
    if q != missing:
      board[cr[q]*MaxSize+cc[q]] = t; nr = cr[q]; nc = cc[q]
    fill(board, h, qr[q], qc[q], nr, nc, tile)
proc tiling_problem*(values: ptr UncheckedArray[int64], length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "tiling_problem".} =
  if values == nil or length != 3: return -1
  let s = values[0]
  if s < 1 or s > MaxSize or (s and (s-1)) != 0 or values[1] < 0 or values[1] >= s or values[2] < 0 or values[2] >= s: return -1
  let size = int(s); var board: array[256, int32]; var tile = 1'i32
  fill(board, size, 0, 0, int(values[1]), int(values[2]), tile)
  let bytes = size*size*4
  if output == nil or int(capacity) < bytes: return -2
  for i in 0 ..< size*size:
    let x = cast[uint32](board[(i div size)*MaxSize+i mod size])
    for b in 0 ..< 4: output[i*4+b] = uint8((x shr (8*b)) and 255)
  int64(bytes)
