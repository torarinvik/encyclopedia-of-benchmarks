## (c) William Landi 1991. Permission to use this code is granted as long as the copyright notice remains in place.
proc prolangs_c_simulator_shiftr*(v: ptr UncheckedArray[int64], n: csize_t): int64 {.cdecl, exportc.} =
  if v == nil or n != 2: return -1
  let operand=v[0]; let raw=v[1]
  if operand < 0 or operand > 255 or raw < 0 or raw > 0xFFFFFF or (operand shr 4) >= 10: return -1
  let shift=uint32((operand and 15)+1)
  let value=uint32(raw)
  var result=value shr shift
  if (value and 0x800000'u32) != 0'u32: result = result or (((1'u32 shl shift)-1'u32) shl (24'u32-shift))
  int64(result and 0xFFFFFF'u32)
