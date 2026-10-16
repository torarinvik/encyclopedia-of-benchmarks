const Limit = 1_000_000'i64

proc writeF64Le(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc cramers_rule_2x2*(v: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "cramers_rule_2x2".} =
  if v == nil or length != 6: return -1
  for i in 0 ..< 6:
    if v[i] < -Limit or v[i] > Limit: return -1
  let a1=v[0]; let b1=v[1]; let c1=v[2]; let a2=v[3]; let b2=v[4]; let c2=v[5]
  let d=a1*b2-a2*b1; let dx=c1*b2-c2*b1; let dy=a1*c2-a2*c1
  if d == 0: return -1
  if output == nil or capacity < 16: return -2
  writeF64Le(output, 0, float64(dx) / float64(d))
  writeF64Le(output, 8, float64(dy) / float64(d))
  2
