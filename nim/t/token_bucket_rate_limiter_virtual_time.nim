const MaxRequests = 63
const MaxInput = 66

proc token_bucket_rate_limiter_virtual_time*(packed: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "token_bucket_rate_limiter_virtual_time".} =
  if packed.isNil or length < 3 or length > MaxInput: return -1
  let capacity = packed[0]
  let rate = packed[1]
  let qv = packed[2]
  if capacity < 0 or capacity > 64 or rate < 0 or rate > 32 or qv < 0 or qv > MaxRequests or
      length != csize_t(3 + qv): return -1
  let q = int(qv)
  for i in 0 ..< q:
    if packed[3 + i] < 0 or packed[3 + i] > 256: return -1

  var tokens = capacity
  var allowed = 0'u64
  for i in 0 ..< q:
    tokens = min(capacity, tokens + packed[3 + i] * rate)
    if tokens > 0:
      allowed = allowed or (1'u64 shl i)
      dec tokens
  int64(allowed)
