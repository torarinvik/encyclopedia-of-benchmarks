const MaxSites = 128
const MaxInputWords = 130
const Sentinel = low(int64) div 2

proc floorDiv(numerator, denominator: int64): int64 =
  var quotient = numerator div denominator
  let remainder = numerator mod denominator
  if remainder != 0 and numerator < 0:
    dec quotient
  quotient

proc storeI64Le(output: ptr UncheckedArray[uint8], word: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[word * 8 + byte] = uint8((bits shr (8 * byte)) and 255)

proc felzenszwalb_huttenlocher_1d_squared_distance_transform*(
    input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "felzenszwalb_huttenlocher_1d_squared_distance_transform".} =
  if input.isNil or length < 2 or length > MaxInputWords:
    return -1
  let n64 = input[0]
  if n64 < 1 or n64 > int64(MaxSites):
    return -1
  let n = int(n64)
  if length != csize_t(n + 1):
    return -1
  for i in 0 ..< n:
    let cost = input[i + 1]
    if cost < 0 or cost > 1_000_000'i64:
      return -1
  if output.isNil or outputCapacity < csize_t(n * 16):
    return -2

  var sites: array[MaxSites, int]
  var starts: array[MaxSites, int64]
  var top = 0
  sites[0] = 0
  starts[0] = Sentinel
  for q in 1 ..< n:
    while true:
      let p = sites[top]
      let numerator = input[q + 1] + int64(q * q)
        - input[p + 1] - int64(p * p)
      let denominator = int64(2 * (q - p))
      let first = floorDiv(numerator, denominator) + 1
      if top == 0 or first > starts[top]:
        inc top
        sites[top] = q
        starts[top] = first
        break
      dec top

  var active = 0
  for x in 0 ..< n:
    while active < top and starts[active + 1] <= int64(x):
      inc active
    let site = sites[active]
    let delta = int64(x - site)
    let distance = delta * delta + input[site + 1]
    storeI64Le(output, 2 * x, distance)
    storeI64Le(output, 2 * x + 1, int64(site))
  int64(n * 16)
