proc matches(s: array[256, char], n, at: int, pattern: string): bool =
  if at + pattern.len > n: return false
  for i in 0 ..< pattern.len:
    if s[at + i] != pattern[i]: return false
  true
proc replaceAt(s: var array[256, char], n: var int, at, oldLen: int, replacement: string) =
  if replacement.len > oldLen:
    var i = n
    while i > at + oldLen:
      dec i
      s[i - oldLen + replacement.len] = s[i]
  else:
    for i in at + oldLen ..< n: s[i - oldLen + replacement.len] = s[i]
  for i in 0 ..< replacement.len: s[at + i] = replacement[i]
  n = n - oldLen + replacement.len
proc isVowel(c: char): bool = c in {'A','E','I','O','U'}
proc nysiis_encoder*(values: ptr UncheckedArray[int64], length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "nysiis_encoder".} =
  if values == nil or length < 2 or length > 65 or values[0] < 1 or values[0] > 64 or length != csize_t(values[0] + 1): return -1
  var s: array[256, char]
  var n = 0
  for i in 0 ..< int(values[0]):
    var c = values[i + 1]
    if c == 32: continue
    if c >= 97 and c <= 122: c -= 32
    if c < 65 or c > 90: return -1
    s[n] = char(c); inc n
  if n == 0: return -1
  let starts = [("MAC","MCC"),("KN","NN"),("K","C"),("PH","FF"),("PF","FF"),("SCH","SSS")]
  for (f,t) in starts:
    if matches(s,n,0,f): replaceAt(s,n,0,f.len,t); break
  let ends = [("EE","Y"),("IE","Y"),("DT","D"),("RT","D"),("NT","D"),("ND","D")]
  for (f,t) in ends:
    if n >= f.len and matches(s,n,n-f.len,f): replaceAt(s,n,n-f.len,f.len,t); break
  let rules = [("EV","AF"),("E","A"),("I","A"),("O","A"),("U","A"),("Q","G"),("Z","S"),("M","N"),("KN","NN"),("K","C"),("SCH","SSS"),("PH","FF")]
  var i = 1
  while i < n:
    var changed = false
    for (f,t) in rules:
      if matches(s,n,i,f): replaceAt(s,n,i,f.len,t); changed = true; break
    if not changed:
      if s[i] == 'H' and (not isVowel(s[i-1]) or (i+1<n and not isVowel(s[i+1]))): s[i] = s[i-1]
      elif s[i] == 'W' and isVowel(s[i-1]): s[i] = s[i-1]
    inc i
  var w = 0
  for j in 0 ..< n:
    if j == 0 or s[j] != s[j-1]: s[w] = s[j]; inc w
  n = w
  if n > 0 and s[n-1] == 'S': dec n
  elif n >= 2 and s[n-2] == 'A' and s[n-1] == 'Y': s[n-2] = 'Y'; dec n
  elif n > 0 and s[n-1] == 'A': dec n
  if n > int(capacity) or (n > 0 and output == nil): return -2
  for j in 0 ..< n: output[j] = uint8(ord(s[j]))
  int64(n)
