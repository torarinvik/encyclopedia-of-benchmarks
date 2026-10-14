## Direct recursive full-string matching for the . and * regular-expression subset.
proc regexMatchRecursive(values: ptr UncheckedArray[int64], textLength: csize_t,
                         patternStart: csize_t, patternLength: csize_t,
                         textIndex: csize_t, patternIndex: csize_t): bool =
  if patternIndex == patternLength:
    return textIndex == textLength
  let atom = values[patternStart + patternIndex]
  if patternIndex + 1 < patternLength and values[patternStart + patternIndex + 1] == ord('*'):
    if regexMatchRecursive(values, textLength, patternStart, patternLength,
                           textIndex, patternIndex + 2):
      return true
    return textIndex < textLength and
      (atom == ord('.') or atom == values[2 + textIndex]) and
      regexMatchRecursive(values, textLength, patternStart, patternLength,
                          textIndex + 1, patternIndex)
  textIndex < textLength and
    (atom == ord('.') or atom == values[2 + textIndex]) and
    regexMatchRecursive(values, textLength, patternStart, patternLength,
                        textIndex + 1, patternIndex + 1)

proc regex_match*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "regex_match".} =
  if length < 2:
    return -1
  if values[0] < 0 or values[0] > 12 or values[1] < 0 or values[1] > 20:
    return -1
  let textLength = csize_t(values[0])
  let patternLength = csize_t(values[1])
  if length != 2 + textLength + patternLength:
    return -1
  let patternStart = 2 + textLength
  for index in 0 ..< textLength:
    if values[2 + index] < ord('a') or values[2 + index] > ord('z'):
      return -1
  for index in 0 ..< patternLength:
    let symbol = values[patternStart + index]
    if not ((symbol >= ord('a') and symbol <= ord('z')) or
            symbol == ord('.') or symbol == ord('*')):
      return -1
    if symbol == ord('*') and
       (index == 0 or values[patternStart + index - 1] == ord('*')):
      return -1
  if regexMatchRecursive(values, textLength, patternStart, patternLength, 0, 0): 1 else: 0
