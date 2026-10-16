const MaxLimit = 1_000_000

proc problem69*(inclusiveLimit: int64): int64 {.cdecl, exportc: "problem69".} =
  if inclusiveLimit < 1 or inclusiveLimit > MaxLimit: return -1
  if inclusiveLimit == 1: return 1
  let limit = int(inclusiveLimit)
  var phi = newSeq[uint32](limit + 1)
  for value in 0 .. limit: phi[value] = uint32(value)
  for number in 2 .. limit:
    if phi[number] != uint32(number): continue
    dec phi[number]
    var multiple = number * 2
    while multiple <= limit:
      phi[multiple] = (phi[multiple] div uint32(number)) * uint32(number - 1)
      multiple += number
  var answer = 1
  for number in 1 .. limit:
    if int64(number) * int64(phi[answer]) > int64(answer) * int64(phi[number]):
      answer = number
  int64(answer)
