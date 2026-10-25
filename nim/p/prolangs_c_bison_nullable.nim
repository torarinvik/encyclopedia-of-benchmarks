## Part of the Bison parser generator,
## Copyright (C) 1984 Bob Corbett and Free Software Foundation, Inc.
##
## BISON is distributed in the hope that it will be useful, but WITHOUT ANY
## WARRANTY.  No author or distributor accepts responsibility to anyone
## for the consequences of using it or for whether it serves any
## particular purpose or works at all, unless he says so in writing.
## Refer to the BISON General Public License for full details.
##
## Everyone is granted permission to copy, modify and redistribute BISON,
## but only under the conditions described in the BISON General Public
## License.  A copy of this license is supposed to have been given to you
## along with BISON so you can know your rights and responsibilities. It
## should be in a file named COPYING. Among other things, the copyright
## notice and this notice must be preserved on all copies.
##
## In other words, you are welcome to use, share and improve this program.
## You are forbidden to forbid anyone else to use, share and improve
## what you give them. Help stamp out software-hoarding!
##
## Modified 2026: bounded numeric grammar adapter; no upstream code is copied.

const MaxNonterminals = 16
const MaxTerminals = 16
const MaxRules = 32
const MaxRhs = 8
const MaxRhsItems = MaxRules * MaxRhs
const MaxInputLength = 3 + MaxRules * (2 + MaxRhs)

proc prolangs_c_bison_nullable*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "prolangs_c_bison_nullable".} =
  if input.isNil or length < 5 or length > MaxInputLength: return -1
  if input[0] < 1 or input[0] > MaxNonterminals or
      input[1] < 0 or input[1] > MaxTerminals or
      input[2] < 1 or input[2] > MaxRules: return -1
  let nonterminalCount = int(input[0])
  let terminalCount = int(input[1])
  let ruleCount = int(input[2])
  var lhs, rhsStart, rhsLength, remaining: array[MaxRules, int]
  var rhs: array[MaxRhsItems, int]
  var eligible: array[MaxRules, bool]
  var nullable: array[MaxNonterminals, bool]
  var symbolQueue: array[MaxNonterminals, int]
  var rhsItems = 0
  var offset = 3
  for rule in 0 ..< ruleCount:
    if offset + 2 > int(length): return -1
    if input[offset] < 0 or input[offset] >= nonterminalCount or
        input[offset + 1] < 0 or input[offset + 1] > MaxRhs: return -1
    lhs[rule] = int(input[offset])
    rhsLength[rule] = int(input[offset + 1])
    offset += 2
    rhsStart[rule] = rhsItems
    if offset + rhsLength[rule] > int(length) or rhsItems + rhsLength[rule] > MaxRhsItems: return -1
    var hasTerminal = false
    for _ in 0 ..< rhsLength[rule]:
      let symbol = input[offset]
      inc offset
      if symbol < 0 or symbol >= nonterminalCount + terminalCount: return -1
      rhs[rhsItems] = int(symbol)
      inc rhsItems
      if int(symbol) >= nonterminalCount: hasTerminal = true
    if rhsLength[rule] > 0 and not hasTerminal:
      eligible[rule] = true
      remaining[rule] = rhsLength[rule]
  if offset != int(length): return -1

  var queueTail = 0
  for rule in 0 ..< ruleCount:
    if rhsLength[rule] == 0 and not nullable[lhs[rule]]:
      nullable[lhs[rule]] = true
      symbolQueue[queueTail] = lhs[rule]
      inc queueTail
  var queueHead = 0
  while queueHead < queueTail:
    let symbol = symbolQueue[queueHead]
    inc queueHead
    for rule in 0 ..< ruleCount:
      if not eligible[rule]: continue
      for j in 0 ..< rhsLength[rule]:
        if rhs[rhsStart[rule] + j] == symbol:
          dec remaining[rule]
          if remaining[rule] == 0 and not nullable[lhs[rule]]:
            nullable[lhs[rule]] = true
            symbolQueue[queueTail] = lhs[rule]
            inc queueTail
  var mask = 0'i64
  var bit = 1'i64
  for symbol in 0 ..< nonterminalCount:
    if nullable[symbol]: mask += bit
    bit *= 2
  mask
