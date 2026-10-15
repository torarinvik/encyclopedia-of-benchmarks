proc van_ecks_sequence*(position: int64): int64 {.cdecl, exportc: "van_ecks_sequence".} =
  if position < 1 or position > 16: return -1
  var lastSeen: array[17, int64]
  var previous = 0'i64
  var current = 2'i64
  while current <= position:
    var next = 0'i64
    if lastSeen[int(previous)] != 0:
      next = current - lastSeen[int(previous)]
    lastSeen[int(previous)] = current
    previous = next
    current += 1
  return previous
