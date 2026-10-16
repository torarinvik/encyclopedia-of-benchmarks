const Small = ["Zero","One","Two","Three","Four","Five","Six","Seven","Eight","Nine","Ten","Eleven","Twelve","Thirteen","Fourteen","Fifteen","Sixteen","Seventeen","Eighteen","Nineteen"]
const Tens = ["","","Twenty","Thirty","Forty","Fifty","Sixty","Seventy","Eighty","Ninety"]
const Scales = ["","Thousand","Million","Billion","Trillion"]
proc add(s: var string, word: string) =
  if s.len > 0: s.add(' ')
  s.add(word)
proc chunk(s: var string, value: int) =
  var x = value
  if x >= 100: s.add(Small[x div 100]); s.add("Hundred"); x = x mod 100
  if x >= 20: s.add(Tens[x div 10]); x = x mod 10
  if x > 0 and x < 20: s.add(Small[x])
proc number_to_words*(values: ptr UncheckedArray[int64], length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "number_to_words".} =
  if values == nil or length < 3 or length > 9 or values[0] < -1 or values[0] > 1 or values[1] < 0 or values[1] > 999999999999999'i64 or values[2] < 0 or values[2] > 6 or length != csize_t(values[2] + 3): return -1
  var nonzero = values[1] != 0
  for i in 3 ..< int(length):
    if values[i] < 0 or values[i] > 9: return -1
    if values[i] != 0: nonzero = true
  if (nonzero and values[0] == 0) or (not nonzero and values[0] != 0): return -1
  var result = ""
  if values[0] < 0: result.add("Negative")
  var whole = uint64(values[1]); var groups: array[5, int]
  for i in 0 ..< 5: groups[i] = int(whole mod 1000); whole = whole div 1000
  var any = false
  for i in countdown(4, 0):
    if groups[i] != 0: chunk(result, groups[i]); if i > 0: result.add(Scales[i]); any = true
  if not any: result.add("Zero")
  var fractionNonzero = false
  for i in 3 ..< int(length):
    if values[i] != 0: fractionNonzero = true
  if fractionNonzero:
    result.add("Point")
    for i in 3 ..< int(length): result.add(Small[int(values[i])])
  if result.len > int(capacity) or (result.len > 0 and output == nil): return -2
  for i in 0 ..< result.len: output[i] = uint8(ord(result[i]))
  int64(result.len)
