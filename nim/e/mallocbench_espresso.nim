## Copyright (c) 1988, 1989, 1990, Regents of the University of California.
## All rights reserved.
##
## Use and copying of this software and preparation of derivative works
## based upon this software are permitted. However, any distribution of
## this software or derivative works must include the above copyright
## notice.
##
## This software is made available AS IS, and neither the Electronics
## Research Laboratory or the University of California make any warranty
## about the software, its performance or its conformity to any
## specification.
##
## Clean-room bounded EXPAND/IRREDUNDANT profile; no upstream code copied.
const MaxVars = 5
const MaxTerms = 32

proc cubeCovers(fixed, value, minterm: uint32): bool {.inline.} =
  (minterm and fixed) == value

proc mallocbench_espresso*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "mallocbench_espresso".} =
  if input.isNil or length != 3: return -1
  let varsValue = input[0]
  if varsValue < 1 or varsValue > MaxVars or input[1] < 0 or input[2] < 0: return -1
  let vars = int(varsValue)
  let minterms = 1 shl vars
  let valid = (1'u64 shl minterms) - 1
  let onset = uint64(input[1])
  let dcset = uint64(input[2])
  if ((onset or dcset) and not valid) != 0 or (onset and dcset) != 0: return -1

  var fixed: array[MaxTerms, uint32]
  var values: array[MaxTerms, uint32]
  var count = 0
  let full = uint32(minterms - 1)
  for m in 0 ..< minterms:
    if (onset and (1'u64 shl m)) != 0:
      fixed[count] = full
      values[count] = uint32(m)
      inc count

  let allowed = onset or dcset
  for i in 0 ..< count:
    for bit in 0 ..< vars:
      let candidateFixed = fixed[i] and not (1'u32 shl bit)
      let candidateValue = values[i] and candidateFixed
      var legal = true
      for m in 0 ..< minterms:
        if cubeCovers(candidateFixed, candidateValue, uint32(m)) and
            (allowed and (1'u64 shl m)) == 0:
          legal = false
          break
      if legal:
        fixed[i] = candidateFixed
        values[i] = candidateValue

  var active: array[MaxTerms, bool]
  for i in 0 ..< count: active[i] = true
  for i in 0 ..< count:
    var redundant = true
    for m in 0 ..< minterms:
      if (onset and (1'u64 shl m)) == 0 or not cubeCovers(fixed[i], values[i], uint32(m)): continue
      var covered = false
      for j in 0 ..< count:
        if j != i and active[j] and cubeCovers(fixed[j], values[j], uint32(m)):
          covered = true
          break
      if not covered:
        redundant = false
        break
    if redundant: active[i] = false

  var cubes = 0'i64
  var literals = 0'i64
  for i in 0 ..< count:
    if not active[i]: continue
    inc cubes
    for bit in 0 ..< vars:
      literals += int64((fixed[i] shr bit) and 1'u32)
  cubes * 1024 + literals
