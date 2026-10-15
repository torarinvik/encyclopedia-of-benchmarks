## Convert a nonnegative reflected Gray-code integer to its binary integer.
proc gray_to_binary*(gray: int64): int64 {.cdecl, exportc: "gray_to_binary".} =
  if gray < 0: return -1
  var binary = gray
  var remaining = gray shr 1
  while remaining != 0:
    binary = binary xor remaining
    remaining = remaining shr 1
  binary
