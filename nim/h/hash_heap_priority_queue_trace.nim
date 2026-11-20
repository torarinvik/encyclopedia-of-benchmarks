const
  MaxBuckets = 8
  MaxOps = 64
  MaxWords = 132
  MaxBytes = 520

type Item = object
  key: uint8
  insertion: uint8

proc before(a, b: Item): bool =
  a.key < b.key or (a.key == b.key and a.insertion < b.insertion)

proc push(heaps: var array[MaxBuckets, array[MaxOps, Item]], sizes: var array[MaxBuckets, int], bucket: int, item: Item) =
  var child = sizes[bucket]
  sizes[bucket] += 1
  heaps[bucket][child] = item
  while child > 0:
    let parent = (child - 1) div 2
    if not before(heaps[bucket][child], heaps[bucket][parent]): break
    swap(heaps[bucket][child], heaps[bucket][parent])
    child = parent

proc pop(heaps: var array[MaxBuckets, array[MaxOps, Item]], sizes: var array[MaxBuckets, int], bucket: int) =
  sizes[bucket] -= 1
  let last = sizes[bucket]
  if last == 0: return
  heaps[bucket][0] = heaps[bucket][last]
  var parent = 0
  while true:
    let left = parent * 2 + 1
    if left >= last: break
    var child = left
    let right = left + 1
    if right < last and before(heaps[bucket][right], heaps[bucket][left]): child = right
    if not before(heaps[bucket][child], heaps[bucket][parent]): break
    swap(heaps[bucket][child], heaps[bucket][parent])
    parent = child

proc writeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc hash_heap_priority_queue_trace*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "hash_heap_priority_queue_trace".} =
  if input.isNil or length < 3 or length > csize_t(MaxWords): return -1
  let universeValue = input[0]
  let bucketValue = input[1]
  let countValue = input[2]
  if universeValue < 1 or universeValue > 128 or bucketValue < 1 or bucketValue > 8 or
      bucketValue > universeValue or countValue < 0 or countValue > int64(MaxOps): return -1
  let universe = int(universeValue)
  let bucketCount = int(bucketValue)
  let count = int(countValue)
  if int(length) != 3 + 2 * count: return -1
  var ops: array[MaxOps, uint8]
  var args: array[MaxOps, uint8]
  for op in 0 ..< count:
    let opcode = input[3 + 2 * op]
    let argument = input[4 + 2 * op]
    if opcode == 0:
      if argument < 0 or argument >= universeValue: return -1
    elif opcode == 1 or opcode == 2:
      if argument != 0: return -1
    else: return -1
    ops[op] = uint8(opcode)
    args[op] = uint8(argument)

  var heaps: array[MaxBuckets, array[MaxOps, Item]]
  var sizes: array[MaxBuckets, int]
  var words: array[MaxOps + 1, int64]
  words[0] = int64(count)
  for op in 0 ..< count:
    if ops[op] == 0:
      let bucket = int(args[op]) * bucketCount div universe
      push(heaps, sizes, bucket, Item(key: args[op], insertion: uint8(op)))
      words[op + 1] = -2
    else:
      var bucket = 0
      while bucket < bucketCount and sizes[bucket] == 0: inc bucket
      if bucket == bucketCount:
        words[op + 1] = -1
      else:
        let item = heaps[bucket][0]
        words[op + 1] = (int64(item.insertion) shl 8) or int64(item.key)
        if ops[op] == 2: pop(heaps, sizes, bucket)

  let required = (count + 1) * 8
  if output.isNil or capacity < csize_t(required): return -2
  for index in 0 .. count: writeI64Le(output, index * 8, words[index])
  int64(required)
