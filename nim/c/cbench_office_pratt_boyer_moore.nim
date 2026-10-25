# /* +++Date last modified: 05-Jul-1997 */
# 
# /*
# **        A Pratt-Boyer-Moore string search, written by Jerry Coffin
# **  sometime or other in 1991.  Removed from original program, and
# **  (incorrectly) rewritten for separate, generic use in early 1992.
# **  Corrected with help from Thad Smith, late March and early
# **  April 1992...hopefully it's correct this time. Revised by Bob Stout.
# **
# **  This is hereby placed in the Public Domain by its author.
# **
# **  10/21/93 rdg  Fixed bug found by Jeff Dunlop
# */
const MaxTextLength = 255
const MaxPatternLength = 64

proc cbench_office_pratt_boyer_moore*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "cbench_office_pratt_boyer_moore".} =
  if values.isNil or length < 3 or length > 321: return -2
  let textLength = values[0]
  let patternLength = values[1]
  if textLength < 0 or textLength > MaxTextLength or patternLength < 1 or patternLength > MaxPatternLength:
    return -2
  if length != csize_t(2 + textLength + patternLength): return -2
  let textStart = 2
  let patternStart = textStart + int(textLength)
  for i in textStart ..< int(length):
    if values[i] < 1 or values[i] > 127: return -2
  var shifts: array[128, int]
  for i in 0 ..< 128: shifts[i] = int(patternLength)
  for i in 0 ..< int(patternLength):
    shifts[int(values[patternStart + i])] = int(patternLength) - i - 1
  var pos = int(patternLength) - 1
  while pos < int(textLength):
    var shift = shifts[int(values[textStart + pos])]
    while pos < int(textLength) and shift > 0:
      pos += shift
      if pos < int(textLength): shift = shifts[int(values[textStart + pos])]
    if pos < int(textLength) and shift == 0:
      let start = pos - int(patternLength) + 1
      var j = 0
      while j < int(patternLength) and values[patternStart + j] == values[textStart + start + j]: inc j
      if j == int(patternLength): return int64(start)
      inc pos
  -1'i64
