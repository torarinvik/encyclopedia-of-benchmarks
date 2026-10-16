const MaxLen = 7
proc nextPerm(a: var array[MaxLen, uint8], n: int): bool =
  var i = n - 1
  while i > 0 and a[i - 1] >= a[i]: dec i
  if i == 0: return false
  var j = n - 1
  while a[j] <= a[i - 1]: dec j
  swap(a[i - 1], a[j])
  var left = i; var right = n - 1
  while left < right:
    swap(a[left], a[right]); inc left; dec right
  true
proc mix(h: uint32, b: uint8): uint32 = uint32((uint64(h xor uint32(b)) * 16777619'u64) and 0xFFFFFFFF'u64)
proc permutate_string*(v: ptr UncheckedArray[int64], n: csize_t): int64 {.cdecl, exportc: "permutate_string".} =
  if v.isNil or n < 2 or n > 8 or v[0] < 1 or v[0] > 7 or n != csize_t(v[0] + 1): return -1
  let len = int(v[0]); var a: array[MaxLen, uint8]
  for i in 0..<len:
    if v[i + 1] < 33 or v[i + 1] > 126: return -1
    a[i] = uint8(v[i + 1])
    for j in 0..<i:
      if a[j] == a[i]: return -1
  for i in 1..<len:
    var j = i
    while j > 0 and a[j - 1] > a[j]: swap(a[j - 1], a[j]); dec j
  var h = 2166136261'u32
  while true:
    for i in 0..<len: h = mix(h, a[i])
    h = mix(h, 0'u8)
    if not nextPerm(a, len): break
  int64(h)
