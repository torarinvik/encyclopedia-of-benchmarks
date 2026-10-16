const MaxLength = 50

proc problem114*(length: int64): int64 {.cdecl, exportc: "problem114".} =
  if length < 0 or length > MaxLength: return -1
  var ways: array[MaxLength + 1, int64]
  for index in 0..int(length): ways[index] = 1
  for rowLength in 3..int(length):
    for blockLength in 3..rowLength:
      for blockStart in 0..<(rowLength - blockLength):
        ways[rowLength] += ways[rowLength - blockStart - blockLength - 1]
      inc ways[rowLength]
  ways[int(length)]
