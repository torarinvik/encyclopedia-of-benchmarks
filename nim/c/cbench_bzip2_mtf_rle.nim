## Altered, bounded clean-room port of a bzip2/libbzip2 1.0.4 coding stage.
##
## This program, "bzip2", the associated library "libbzip2", and all
## documentation, are copyright (C) 1996-2006 Julian R Seward. All rights reserved.
##
## Redistribution and use in source and binary forms, with or without
## modification, are permitted provided that the following conditions are met:
## 1. Redistributions of source code must retain the above copyright notice, this
##    list of conditions and the following disclaimer.
## 2. The origin of this software must not be misrepresented; you must not claim
##    that you wrote the original software. If you use this software in a
##    product, an acknowledgment in the product documentation would be
##    appreciated but is not required.
## 3. Altered source versions must be plainly marked as such, and must not be
##    misrepresented as being the original software.
## 4. The name of the author may not be used to endorse or promote products
##    derived from this software without specific prior written permission.
##
## THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
## WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
## MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
## EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
## SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
## PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
## OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
## WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
## OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
## ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
## Julian Seward, Cambridge, UK. jseward@bzip.org
## bzip2/libbzip2 version 1.0.4 of 20 December 2006

const MaxBlock = 32
const MaxTokens = 33
const MaxInput = 68

proc emitZeroRun(tokens: var array[MaxTokens, uint8], used: var int, count: int) =
  if count == 0: return
  var value = count - 1
  while true:
    tokens[used] = (if (value and 1) != 0: 1'u8 else: 0'u8)
    inc used
    if value < 2: break
    value = (value - 2) div 2

proc cbench_bzip2_mtf_rle*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "cbench_bzip2_mtf_rle".} =
  if input.isNil or inputLength < 3 or inputLength > MaxInput: return -1
  var staged: array[MaxTokens, uint8]
  var stagedCount = 0

  if input[0] == 0:
    if input[1] != 0 or input[2] < 1 or input[2] > MaxBlock: return -1
    let blockLength = int(input[2])
    if inputLength != csize_t(3 + blockLength): return -1
    var alphabet: array[MaxBlock, uint8]
    var alphabetLength = 0
    for i in 0 ..< blockLength:
      let value = input[3 + i]
      if value < 0 or value > 255: return -1
      var at = 0
      while at < alphabetLength and alphabet[at] < uint8(value): inc at
      if at < alphabetLength and alphabet[at] == uint8(value): continue
      for j in countdown(alphabetLength - 1, at):
        alphabet[j + 1] = alphabet[j]
      alphabet[at] = uint8(value)
      inc alphabetLength
    var order: array[MaxBlock, uint8]
    for i in 0 ..< alphabetLength: order[i] = uint8(i)
    var pendingZeros = 0
    for i in 0 ..< blockLength:
      let value = uint8(input[3 + i])
      var symbol = 0
      while alphabet[symbol] != value: inc symbol
      var rank = 0
      while int(order[rank]) != symbol: inc rank
      if rank == 0:
        inc pendingZeros
        continue
      emitZeroRun(staged, stagedCount, pendingZeros)
      pendingZeros = 0
      staged[stagedCount] = uint8(rank + 1)
      inc stagedCount
      let moved = order[rank]
      for j in countdown(rank, 1): order[j] = order[j - 1]
      order[0] = moved
    emitZeroRun(staged, stagedCount, pendingZeros)
    staged[stagedCount] = uint8(alphabetLength + 1)
    inc stagedCount
  elif input[0] == 1:
    if input[1] < 1 or input[1] > MaxBlock or input[2] < 2 or input[2] > MaxTokens: return -1
    let alphabetLength = int(input[1])
    let tokenCount = int(input[2])
    if inputLength != csize_t(3 + alphabetLength + tokenCount): return -1
    var order: array[MaxBlock, uint8]
    for i in 0 ..< alphabetLength:
      let symbol = input[3 + i]
      if symbol < 0 or symbol > 255 or (i > 0 and input[2 + i] >= symbol): return -1
      order[i] = uint8(symbol)
    let tokenStart = 3 + alphabetLength
    let eob = int64(alphabetLength + 1)
    for i in 0 ..< tokenCount:
      let token = input[tokenStart + i]
      if token < 0 or token > eob or (i + 1 < tokenCount and token == eob): return -1
    if input[tokenStart + tokenCount - 1] != eob: return -1
    var index = 0
    while index + 1 < tokenCount:
      var token = input[tokenStart + index]
      if token == 0 or token == 1:
        var runCount = 0
        var weight = 1
        while index + 1 < tokenCount:
          token = input[tokenStart + index]
          if token != 0 and token != 1: break
          if weight > MaxBlock: return -1
          let add = int(token + 1) * weight
          if runCount + add > MaxBlock: return -1
          runCount += add
          weight *= 2
          inc index
        if stagedCount + runCount > MaxBlock: return -1
        for _ in 0 ..< runCount:
          staged[stagedCount] = order[0]
          inc stagedCount
        continue
      if token < 2 or token >= eob: return -1
      let rank = int(token - 1)
      if rank >= alphabetLength or stagedCount >= MaxBlock: return -1
      let moved = order[rank]
      staged[stagedCount] = moved
      inc stagedCount
      for j in countdown(rank, 1): order[j] = order[j - 1]
      order[0] = moved
      inc index
    if stagedCount == 0: return -1
  else:
    return -1

  if output.isNil or outputCapacity < csize_t(stagedCount): return -2
  for i in 0 ..< stagedCount: output[i] = staged[i]
  int64(stagedCount)
