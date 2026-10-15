## Compare Kernighan, modulo-shift, and byte-lookup set-bit counters.
proc count_number_of_one_bits*(number, methodId: int64): int64
    {.cdecl, exportc: "count_number_of_one_bits".} =
  if number < 0 or number > 4_294_967_295'i64 or methodId < 0 or methodId > 2: return -1
  var remaining = uint32(number)
  var count: int64 = 0
  if methodId == 0:
    while remaining != 0:
      remaining = remaining and (remaining - 1'u32)
      inc count
    return count
  if methodId == 1:
    while remaining != 0:
      if remaining mod 2'u32 == 1'u32: inc count
      remaining = remaining shr 1
    return count
  var lookup: array[256, int64]
  for index in 1 ..< 256:
    lookup[index] = lookup[index shr 1] + int64(index and 1)
  count = lookup[int(remaining and 0xff'u32)] + lookup[int((remaining shr 8) and 0xff'u32)] +
      lookup[int((remaining shr 16) and 0xff'u32)] + lookup[int((remaining shr 24) and 0xff'u32)]
  count
