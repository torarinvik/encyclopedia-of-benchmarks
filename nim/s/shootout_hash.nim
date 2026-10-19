const
  MaxN = 3_500_000'i64
  BucketPrimes: array[28, uint32] = [
    53'u32, 97, 193, 389, 769, 1543, 3079, 6151, 12289, 24593,
    49157, 98317, 196613, 393241, 786433, 1572869, 3145739,
    6291469, 12582917, 25165843, 50331653, 100663319, 201326611,
    402653189, 805306457, 1610612741, 3221225473, 4294967291'u32
  ]

proc bucketCountFor(n: uint32): int =
  for prime in BucketPrimes:
    if prime >= n: return int(prime)
  int(BucketPrimes[^1])

proc hashKey(valueInput, base: uint32, bucketCount: int): int =
  var value = valueInput
  var reverse: array[16, uint8]
  var length = 0
  while true:
    let digit = value mod base
    reverse[length] = uint8(if digit < 10: 48'u32 + digit else: 87'u32 + digit)
    inc length
    value = value div base
    if value == 0: break
  var hash = 0'u64
  while length > 0:
    dec length
    hash = 5'u64 * hash + uint64(reverse[length])
  int(hash mod uint64(bucketCount))

proc hexKeyMatchesDecimal(hexValueInput, decimalValueInput: uint32): bool =
  var hexValue = hexValueInput
  var decimalValue = decimalValueInput
  while hexValue != 0 and decimalValue != 0:
    let digit = hexValue and 15'u32
    if digit >= 10 or digit != decimalValue mod 10'u32: return false
    hexValue = hexValue shr 4
    decimalValue = decimalValue div 10'u32
  hexValue == 0 and decimalValue == 0

proc shootout_hash*(n: int64): int64 {.cdecl, exportc: "shootout_hash".} =
  if n < 0 or n > MaxN: return -1
  let bound = uint32(n)
  let bucketCount = bucketCountFor(bound)
  var heads = newSeq[uint32](bucketCount)
  var next = newSeq[uint32](int(bound) + 1)

  var value = 1'u32
  while value <= bound:
    let bucket = hashKey(value, 16'u32, bucketCount)
    var node = heads[bucket]
    var previous = 0'u32
    while node != 0:
      if node == value: break
      previous = node
      node = next[int(node)]
    if node == 0:
      if previous == 0: heads[bucket] = value
      else: next[int(previous)] = value
    inc value

  var found = 0'i64
  value = bound
  while value > 0:
    let bucket = hashKey(value, 10'u32, bucketCount)
    var node = heads[bucket]
    while node != 0:
      if hexKeyMatchesDecimal(node, value):
        inc found
        break
      node = next[int(node)]
    dec value
  found
