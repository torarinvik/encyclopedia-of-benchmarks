const MaxNum = 2_147_483_647'u64
const InvalidResult = -1'i64

proc find_nth_bit*(num, n: uint64): int64 {.cdecl, exportc: "find_nth_bit".} =
  if num > MaxNum or n < 1 or n > 31: return InvalidResult
  let value = int32(num)
  let shift = int32(n - 1)
  int64((value and (1'i32 shl shift)) shr shift)
