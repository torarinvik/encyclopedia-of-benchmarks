const MaxAttributes = 51
const MaxInputLength = 1 + 2 * MaxAttributes

proc keyFloatBitsValid(payload: int64): int64 =
  if payload < 0 or payload > 0xffff_ffff'i64: return -1
  let bits = uint32(payload)
  let exponent = (bits shr 23) and 0xff'u32
  let fraction = bits and 0x7f_ffff'u32
  if exponent == 0xff'u32 and fraction == 0: return 0
  1

proc versabench_dbms_valid_attributes*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "versabench_dbms_valid_attributes".} =
  if values == nil or length < 1 or length > csize_t(MaxInputLength + 1): return -1
  let rawCount = values[0]
  if rawCount < 0 or rawCount > MaxAttributes or length != csize_t(1 + 2 * int(rawCount)): return -1
  for i in 0 ..< int(rawCount):
    let code = values[1+2*i]; let payload = values[2+2*i]
    if code < 0 or code > 50: return 0
    if code < 8:
      let valid = keyFloatBitsValid(payload)
      if valid < 0: return -1
      if valid == 0: return 0
    else:
      if payload != 0 and payload != 1: return -1
      if payload == 0: return 0
  1
