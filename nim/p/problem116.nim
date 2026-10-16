## Count single-color block replacements for lengths two, three, and four.
const MaxLength = 91'i64

proc problem116*(length: int64): int64 {.cdecl, exportc: "problem116".} =
  if length > MaxLength: return -1
  if length < 0: return -1
  var ways: array[276, int64]
  var rowLength = 0'i64
  while rowLength <= length:
    var tileLength = 2'i64
    while tileLength < 5:
      let color = tileLength - 2
      var tileStart = 0'i64
      while tileStart < rowLength - tileLength + 1:
        let suffix = rowLength - tileStart - tileLength
        let index = int(rowLength * 3 + color)
        let suffixIndex = int(suffix * 3 + color)
        ways[index] += ways[suffixIndex] + 1
        inc tileStart
      inc tileLength
    inc rowLength
  ways[int(length * 3)] + ways[int(length * 3 + 1)] + ways[int(length * 3 + 2)]
