const MaxInput = 130
const MaxOutput = 24

proc putWord(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc blr_linearity_test*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "blr_linearity_test".} =
  if input.isNil or length < 2 or length > csize_t(MaxInput): return -1
  let n64, q64 = input[0], input[1]
  if n64 < 1 or n64 > 6 or q64 < 1 or q64 > 32: return -1
  let n, q = int(n64), int(q64)
  let domain = 1 shl n
  if int(length) != 2 + domain + 2*q: return -1
  let tableAt = 2
  let tapeAt = tableAt + domain
  for i in 0..<domain:
    if input[tableAt+i] != 0 and input[tableAt+i] != 1: return -1
  for i in 0..<2*q:
    if input[tapeAt+i] < 0 or input[tapeAt+i] >= int64(domain): return -1
  var rounds = 0
  var accepted = 1'i64
  for round in 0..<q:
    let x, y = int(input[tapeAt+2*round]), int(input[tapeAt+2*round+1])
    inc rounds
    if (input[tableAt+x] xor input[tableAt+y]) != input[tableAt+(x xor y)]:
      accepted = 0
      break
  if output.isNil or capacity < csize_t(MaxOutput): return -2
  putWord(output, 0, accepted)
  putWord(output, 8, int64(rounds))
  putWord(output, 16, int64(3*rounds))
  MaxOutput
