proc so1*(threshold: int64): int64 {.cdecl, exportc: "so1".} =
  if threshold < -2_147_483_648'i64 or threshold > 1_000_000_000'i64:
    return -1

  var first = 1'i64
  var second = 2'i64
  var total = 0'i64
  while second <= threshold:
    if second mod 2 == 0:
      total += second
    let temporary = first
    first = second
    second = temporary + first
  return total
