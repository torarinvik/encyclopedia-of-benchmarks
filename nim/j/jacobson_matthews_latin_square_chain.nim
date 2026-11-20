type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]
  Move = object
    i, j, k, ip, jp, kp: int

const MaxN = 4
const MaxCells = 64
const MaxMoves = 48
const MaxWords = 66

proc at(n, i, j, k: int): int {.inline.} = (i * n + j) * n + k

proc selectMove(tensor: array[MaxCells, int64], n, choice: int,
    selected: var Move): bool =
  var moves: array[MaxMoves, Move]
  var defects = 0
  var pi, pj, pk, count = 0
  for i in 0 ..< n:
    for j in 0 ..< n:
      for k in 0 ..< n:
        if tensor[at(n, i, j, k)] == -1:
          inc defects
          pi = i; pj = j; pk = k
  if defects > 1: return false
  if defects == 1:
    for ip in 0 ..< n:
      for jp in 0 ..< n:
        for kp in 0 ..< n:
          if ip != pi and jp != pj and kp != pk and
              tensor[at(n, pi, pj, kp)] == 1 and tensor[at(n, pi, jp, pk)] == 1 and
              tensor[at(n, ip, pj, pk)] == 1:
            moves[count] = Move(i: pi, j: pj, k: pk, ip: ip, jp: jp, kp: kp)
            inc count
    if count != 8: return false
  else:
    for i in 0 ..< n:
      for j in 0 ..< n:
        for k in 0 ..< n:
          if tensor[at(n, i, j, k)] != 0: continue
          var ip = n; var jp = n; var kp = n
          for x in 0 ..< n:
            if tensor[at(n, x, j, k)] == 1: ip = x
            if tensor[at(n, i, x, k)] == 1: jp = x
            if tensor[at(n, i, j, x)] == 1: kp = x
          if ip == n or jp == n or kp == n: return false
          moves[count] = Move(i: i, j: j, k: k, ip: ip, jp: jp, kp: kp)
          inc count
    if count != n*n*n - n*n: return false
  if choice < 0 or choice >= count: return false
  selected = moves[choice]
  true

proc applyChoice(tensor: var array[MaxCells, int64], n, choice: int): bool =
  var m: Move
  if not selectMove(tensor, n, choice, m): return false
  inc tensor[at(n, m.i, m.j, m.k)]; inc tensor[at(n, m.ip, m.jp, m.k)]
  inc tensor[at(n, m.ip, m.j, m.kp)]; inc tensor[at(n, m.i, m.jp, m.kp)]
  dec tensor[at(n, m.ip, m.j, m.k)]; dec tensor[at(n, m.i, m.jp, m.k)]
  dec tensor[at(n, m.i, m.j, m.kp)]; dec tensor[at(n, m.ip, m.jp, m.kp)]
  true

proc writeI64Le(output: U8Output, offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (byte * 8)) and 255'u64)

proc jacobson_matthews_latin_square_chain*(input: I64Input, length: csize_t,
    output: U8Output, outputCapacity: csize_t): int64 {.cdecl, exportc: "jacobson_matthews_latin_square_chain".} =
  if input == nil or length < 2 or length > 14: return -1
  let nv = input[0]; let sv = input[1]
  if nv < 2 or nv > int64(MaxN) or sv < 0 or sv > 12 or length != csize_t(2 + sv): return -1
  let n = int(nv); let steps = int(sv)
  var tensor: array[MaxCells, int64]
  for i in 0 ..< n:
    for j in 0 ..< n: tensor[at(n, i, j, (i+j) mod n)] = 1
  for step in 0 ..< steps:
    let choice = input[2 + step]
    if choice < 0 or choice >= int64(MaxMoves) or not applyChoice(tensor, n, int(choice)): return -1
  let wordCount = 2 + n*n*n
  let outputBytes = wordCount * 8
  if output == nil or outputCapacity < csize_t(outputBytes): return -2
  var words: array[MaxWords, int64]
  words[0] = nv; words[1] = sv
  for i in 0 ..< n*n*n: words[2+i] = tensor[i]
  for i in 0 ..< wordCount: writeI64Le(output, i*8, words[i])
  int64(outputBytes)
