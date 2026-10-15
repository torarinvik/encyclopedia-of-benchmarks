const Words = ["zero","one","two","three","four","five","six","seven","eight","nine","ten","eleven","twelve","thirteen","fourteen","fifteen","sixteen","seventeen","eighteen","nineteen","twenty","thirty","forty","fifty","sixty","seventy","eighty","ninety","quadrillion","trillion","billion","million","thousand","hundred","billiard","milliard","crore crore","lakh crore","crore","lakh","negative"]
const ShortPowers = [1_000_000_000_000_000'u64,1_000_000_000_000'u64,1_000_000_000'u64,1_000_000'u64,1_000'u64,100'u64]
const LongPowers = [1_000_000_000_000_000'u64,1_000_000_000'u64,1_000_000'u64,1_000'u64,100'u64]
const IndianPowers = [100_000_000_000_000'u64,1_000_000_000_000'u64,10_000_000'u64,100_000'u64,1_000'u64,100'u64]
proc scalePower(system, index: int): uint64 =
  case system
  of 0: ShortPowers[index]
  of 1: LongPowers[index]
  else: IndianPowers[index]
proc scaleWord(system, index: int): int =
  case system
  of 0: [28,29,30,31,32,33][index]
  of 1: [34,35,31,32,33][index]
  else: [36,37,38,39,32,33][index]
proc scaleCount(system: int): int = if system == 1: 5 else: 6
proc appendWord(output: var string, id: int, separate = true) =
  if separate and output.len > 0: output.add(' ')
  output.add(Words[id])
proc appendSmall(n: uint64, output: var string) =
  if n < 10: appendWord(output, int(n)); return
  if n < 20: appendWord(output, int(n) + 10); return
  appendWord(output, int(n div 10) + 18)
  if n mod 10 != 0:
    output.add('-')
    appendWord(output, int(n mod 10), false)
proc appendNumber(nInput: uint64, system: int, output: var string, depth: int) =
  if depth > 8: return
  var n = nInput
  let initialLength = output.len
  for i in 0..<scaleCount(system):
    let group = n div scalePower(system, i)
    n = n mod scalePower(system, i)
    if group == 0: continue
    if group >= 100: appendNumber(group, system, output, depth + 1)
    else: appendSmall(group, output)
    appendWord(output, scaleWord(system, i))
  if n > 0 or output.len == initialLength: appendSmall(n, output)

proc convert_number_to_words*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "convert_number_to_words".} =
  if input.isNil or length != 2 or input[1] < 0 or input[1] > 2: return -1
  let system = int(input[1])
  let number = input[0]
  let limit = if system == 0: 999_999_999_999_999_999'i64 else: 9_000_000_000_000_000_000'i64
  if number < -limit or number > limit: return -1
  let magnitude = uint64(if number < 0: -number else: number)
  var words = ""
  if number < 0: appendWord(words, 40)
  appendNumber(magnitude, system, words, 0)
  if capacity < csize_t(words.len) or output.isNil: return -2
  for i in 0..<words.len: output[i] = uint8(ord(words[i]))
  int64(words.len)
