## Hash a bounded ASCII codepoint array with the Python ELF recurrence.
const MaxCodepoints = 8

proc elf_hash*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "elf_hash".} =
  if length > csize_t(MaxCodepoints) or (input == nil and length != 0): return -1
  var hash = 0'u64
  for index in 0 ..< int(length):
    let codepoint = input[index]
    if codepoint < 0 or codepoint > 127: return -1
    hash = (hash shl 4) + uint64(codepoint)
    let high = hash and 0xF0000000'u64
    if high != 0: hash = hash xor (high shr 24)
    hash = hash xor high
  int64(hash)
