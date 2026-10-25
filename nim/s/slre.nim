# SPDX-License-Identifier: GPL-3.0-or-later
# Bounded modified profile of Embench slre; see package NOTICE.txt for upstream attribution.
proc atom(x: int64): bool = (x >= 97 and x <= 122) or x == 46
proc slre*(values: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "slre".} =
  if length < 2: return -2
  if values[0] < 0 or values[0] > 24 or values[1] < 1 or values[1] > 24: return -2
  let t = int(values[0]); let p = int(values[1]); let ps = 2+t
  if int(length) != ps+p: return -2
  for i in 0..<t:
    if values[2+i] < 97 or values[2+i] > 122: return -2
  var lo=0; var hi=p; var anchoredStart=false; var anchoredEnd=false
  if values[ps] == 94: anchoredStart=true; inc lo
  if lo < hi and values[ps+hi-1] == 36: anchoredEnd=true; dec hi
  var i=lo; var nonempty=false
  while i<hi:
    let x=values[ps+i]
    if x == 124:
      if not nonempty: return -2
      nonempty=false; inc i; continue
    if not atom(x): return -2
    nonempty=true; inc i
    if i<hi and values[ps+i] == 63: inc i
  if not nonempty: return -2
  for start in 0..t:
    if anchoredStart and start>0: break
    var b=lo
    while b<=hi:
      var e=b
      while e<hi and values[ps+e] != 124:
        inc e
        if e<hi and values[ps+e] == 63: inc e
      var q=b; var pos=start; var ok=true
      while q<e:
        let x=values[ps+q]; let optional=q+1<e and values[ps+q+1] == 63
        if pos<t and (x==46 or x==values[2+pos]): inc pos
        elif not optional: ok=false; break
        if optional: q+=2 else: inc q
      if ok and (not anchoredEnd or pos==t): return int64(pos)
      if e==hi: break
      b=e+1
  return -1
