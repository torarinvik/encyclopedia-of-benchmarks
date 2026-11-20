const
  MaxUniverse = 32
  MaxOperations = 30
  MaxLength = 63

proc sparse_set_dense_array*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "sparse_set_dense_array".} =
  if input == nil or length < 2 or length > csize_t(MaxLength): return -1
  if input[0] < 1 or input[0] > int64(MaxUniverse) or input[1] < 0 or input[1] > int64(MaxOperations): return -1
  let universe = int(input[0])
  let count = int(input[1])
  if int(length) != 2+2*count: return -1
  for i in 0 ..< count:
    let opcode = input[2+2*i]
    let key = input[3+2*i]
    if opcode < 0 or opcode > 3 or key < 0 or key >= int64(universe): return -1
    if opcode == 3 and key != 0: return -1

  var dense: array[MaxUniverse, int]
  var sparse: array[MaxUniverse, int]
  for key in 0 ..< universe: sparse[key] = universe
  var size = 0
  var answers = 0'i64
  for i in 0 ..< count:
    let opcode = int(input[2+2*i])
    let key = int(input[3+2*i])
    let index = sparse[key]
    let present = index < size and dense[index] == key
    var status = 0'i64
    if opcode == 0:
      if not present:
        dense[size] = key
        sparse[key] = size
        inc size
        status = 1
    elif opcode == 1:
      if present:
        let last = dense[size-1]
        dense[index] = last
        sparse[last] = index
        dec size
        status = 1
    elif opcode == 2:
      if present: status = 1
    else:
      if size != 0: status = 1
      size = 0
    answers = (answers shl 1) or status
  var finalMask = 0'i64
  for i in 0 ..< size: finalMask = finalMask or (1'i64 shl dense[i])
  (finalMask shl count) or answers
