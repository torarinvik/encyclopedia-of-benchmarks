proc make_change_sequence*(amount: int64): int64 {.cdecl, exportc: "make_change_sequence".} =
  if amount < 0 or amount > 128: return -1
  var values: array[129, int64]
  values[0] = 1; values[1] = 1; values[2] = 2; values[3] = 2; values[4] = 3
  values[5] = 4; values[6] = 5; values[7] = 6; values[8] = 7; values[9] = 8
  values[10] = 11; values[11] = 12; values[12] = 15; values[13] = 16
  values[14] = 19; values[15] = 22; values[16] = 25
  var n = 17'i64
  while n <= amount:
    values[int(n)] = values[int(n - 2)] + values[int(n - 5)] - values[int(n - 7)] +
                     values[int(n - 10)] - values[int(n - 12)] - values[int(n - 15)] +
                     values[int(n - 17)] + 1
    n += 1
  return values[int(amount)]
