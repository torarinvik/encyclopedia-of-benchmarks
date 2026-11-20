const
  MaxCapacity = 32
  MaxInputLength = 35
  MaxKey = 1_000_000'i64

proc lcfs_hashing*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "lcfs_hashing".} =
  if input == nil or length < 2 or length > csize_t(MaxInputLength): return -1
  let capacityValue = input[0]
  let countValue = input[1]
  if capacityValue < 1 or capacityValue > MaxCapacity or countValue < 0 or countValue > capacityValue: return -1
  if length != csize_t(countValue + 2): return -1
  let capacity = int(capacityValue)
  let count = int(countValue)
  for i in 0 ..< count:
    let key = input[i + 2]
    if key < 0 or key > MaxKey: return -1
    for j in 0 ..< i:
      if input[j + 2] == key: return -1

  var table: array[MaxCapacity, int64]
  for i in 0 ..< capacity: table[i] = -1
  var displacements = 0'i64
  for i in 0 ..< count:
    var incoming = input[i + 2]
    var slot = int(incoming mod capacityValue)
    var probes = 0
    while table[slot] != -1:
      if probes >= capacity: return -1
      let resident = table[slot]
      table[slot] = incoming
      incoming = resident
      slot = (slot + 1) mod capacity
      inc probes
      inc displacements
    table[slot] = incoming
  displacements
