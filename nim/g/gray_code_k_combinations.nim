const MaxUniverse = 12
type I64Input = ptr UncheckedArray[int64]
type ByteOutput = ptr UncheckedArray[uint8]

proc gray_code_k_combinations*(input: I64Input, length: csize_t,
    output: ByteOutput, capacity: csize_t): int64
    {.cdecl, exportc: "gray_code_k_combinations".} =
  if input.isNil or length != 2 or input[0] < 0 or input[0] > MaxUniverse or
      input[1] < 0 or input[1] > input[0]: return -1
  let n = int(input[0])
  let k = int(input[1])
  let smaller = min(k, n - k)
  var count = 1
  for factor in 1 .. smaller:
    count = count * (n - smaller + factor) div factor
  let required = 2 + 2 * count
  if output.isNil or capacity < csize_t(required): return -2
  output[0] = uint8(count and 255)
  output[1] = uint8((count shr 8) and 255)

  var emitted = 0
  for index in 0 ..< (1 shl n):
    let mask = index xor (index shr 1)
    var remaining = mask
    var population = 0
    while remaining > 0:
      remaining = remaining and (remaining - 1)
      inc population
    if population == k:
      output[2 + 2 * emitted] = uint8(mask and 255)
      output[3 + 2 * emitted] = uint8((mask shr 8) and 255)
      inc emitted
  int64(count)
