## Clean-room bounded port of Philips's 2000 Double Metaphone rules.
## Input is [byte_count, ASCII/Latin-1 bytes]; output is two length-prefixed keys.
const TextLimit = 32
const Pad = 5
const KeyLimit = 4

type Encoder = object
  text: array[TextLimit + Pad, uint8]
  primary, secondary: array[KeyLimit, uint8]
  length, primaryLen, secondaryLen: int
  alternateSeen: bool

proc at(s: Encoder, i: int): uint8 {.inline.} =
  if i < 0 or i >= TextLimit + Pad: return uint8(' ')
  s.text[i]

proc has(s: Encoder, i: int, pattern: string): bool =
  if i < 0 or i + pattern.len > TextLimit + Pad: return false
  for j in 0 ..< pattern.len:
    if s.text[i+j] != uint8(pattern[j]): return false
  true

proc vowel(s: Encoder, i: int): bool {.inline.} =
  if i < 0 or i >= s.length: return false
  let c = s.at(i)
  c == uint8('A') or c == uint8('E') or c == uint8('I') or
    c == uint8('O') or c == uint8('U') or c == uint8('Y')

proc append(dst: var array[KeyLimit, uint8], size: var int, value: string) =
  for c in value:
    if size >= KeyLimit: break
    dst[size] = uint8(c)
    inc size

proc same(s: var Encoder, value: string) =
  s.primary.append(s.primaryLen, value)
  s.secondary.append(s.secondaryLen, value)

proc choice(s: var Encoder, main, alt: string) =
  s.primary.append(s.primaryLen, main)
  if alt.len > 0:
    s.alternateSeen = true
    if alt[0] != ' ': s.secondary.append(s.secondaryLen, alt)
  elif main.len > 0 and main[0] != ' ':
    s.secondary.append(s.secondaryLen, main)

proc slavo(s: Encoder): bool =
  for i in 0 ..< s.length:
    if s.at(i) == uint8('W') or s.at(i) == uint8('K') or s.has(i, "CZ") or s.has(i, "WITZ"):
      return true
  false

proc ruleC(s: var Encoder, i: int): int =
  if i > 1 and not s.vowel(i-2) and s.has(i-1,"ACH") and s.at(i+2) != uint8('I') and
      (s.at(i+2) != uint8('E') or s.has(i-2,"BACHER") or s.has(i-2,"MACHER")):
    s.same("K"); return i+2
  if i == 0 and s.has(i,"CAESAR"): s.same("S"); return i+2
  if s.has(i,"CHIA"): s.same("K"); return i+2
  if s.has(i,"CH"):
    if i > 0 and s.has(i,"CHAE"): s.choice("K","X"); return i+2
    if i == 0 and (s.has(i+1,"HARAC") or s.has(i+1,"HARIS") or s.has(i+1,"HOR") or
        s.has(i+1,"HYM") or s.has(i+1,"HIA") or s.has(i+1,"HEM")) and not s.has(0,"CHORE"):
      s.same("K"); return i+2
    let hard = s.has(0,"VAN ") or s.has(0,"VON ") or s.has(0,"SCH") or s.has(i-2,"ORCHES") or
      s.has(i-2,"ARCHIT") or s.has(i-2,"ORCHID") or s.at(i+2) == uint8('T') or s.at(i+2) == uint8('S') or
      ((s.at(i-1) in [uint8('A'),uint8('O'),uint8('U'),uint8('E')] or i == 0) and
       s.at(i+2) in [uint8('L'),uint8('R'),uint8('N'),uint8('M'),uint8('B'),uint8('H'),uint8('F'),uint8('V'),uint8('W'),uint8(' ')])
    if hard: s.same("K")
    elif i > 0:
      if s.has(0,"MC"): s.same("K") else: s.choice("X","K")
    else: s.same("X")
    return i+2
  if s.has(i,"CZ") and not s.has(i-2,"WICZ"): s.choice("S","X"); return i+2
  if s.has(i+1,"CIA"): s.same("X"); return i+3
  if s.has(i,"CC") and not (i == 1 and s.at(0) == uint8('M')):
    if s.at(i+2) in [uint8('I'),uint8('E'),uint8('H')] and not s.has(i+2,"HU"):
      if (i == 1 and s.at(i-1) == uint8('A')) or s.has(i-1,"UCCEE") or s.has(i-1,"UCCES"): s.same("KS")
      else: s.same("X")
      return i+3
    s.same("K"); return i+2
  if s.has(i,"CK") or s.has(i,"CG") or s.has(i,"CQ"): s.same("K"); return i+2
  if s.has(i,"CI") or s.has(i,"CE") or s.has(i,"CY"):
    if s.has(i,"CIO") or s.has(i,"CIE") or s.has(i,"CIA"): s.choice("S","X")
    else: s.same("S")
    return i+2
  s.same("K")
  if s.has(i+1," C") or s.has(i+1," Q") or s.has(i+1," G"): return i+3
  if s.at(i+1) in [uint8('C'),uint8('K'),uint8('Q')] and not s.has(i+1,"CE") and not s.has(i+1,"CI"): return i+2
  i+1

proc ruleG(s: var Encoder, i: int, germanic: bool): int =
  if s.at(i+1) == uint8('H'):
    if i > 0 and not s.vowel(i-1): s.same("K"); return i+2
    if i == 0:
      if s.at(i+2) == uint8('I'): s.same("J") else: s.same("K")
      return i+2
    if (i>1 and s.at(i-2) in [uint8('B'),uint8('H'),uint8('D')]) or
       (i>2 and s.at(i-3) in [uint8('B'),uint8('H'),uint8('D')]) or
       (i>3 and s.at(i-4) in [uint8('B'),uint8('H')]): return i+2
    if i>2 and s.at(i-1)==uint8('U') and s.at(i-3) in [uint8('C'),uint8('G'),uint8('L'),uint8('R'),uint8('T')]: s.same("F")
    elif i>0 and s.at(i-1)!=uint8('I'): s.same("K")
    return i+2
  if s.at(i+1) == uint8('N'):
    if i==1 and s.vowel(0) and not germanic: s.choice("KN","N")
    elif not s.has(i+2,"EY") and s.at(i+1)!=uint8('Y') and not germanic: s.choice("N","KN")
    else: s.same("KN")
    return i+2
  if s.has(i+1,"LI") and not germanic: s.choice("KL","L"); return i+2
  if i==0 and (s.at(i+1)==uint8('Y') or s.has(i+1,"ES") or s.has(i+1,"EP") or s.has(i+1,"EB") or
      s.has(i+1,"EL") or s.has(i+1,"EY") or s.has(i+1,"IB") or s.has(i+1,"IL") or s.has(i+1,"IN") or
      s.has(i+1,"IE") or s.has(i+1,"EI") or s.has(i+1,"ER")):
    s.choice("K","J"); return i+2
  if (s.has(i+1,"ER") or s.at(i+1)==uint8('Y')) and not s.has(0,"DANGER") and not s.has(0,"RANGER") and
      not s.has(0,"MANGER") and s.at(i-1)!=uint8('E') and s.at(i-1)!=uint8('I') and
      not s.has(i-1,"RGY") and not s.has(i-1,"OGY"):
    s.choice("K","J"); return i+2
  if s.at(i+1) in [uint8('E'),uint8('I'),uint8('Y')] or s.has(i-1,"AGGI") or s.has(i-1,"OGGI"):
    if s.has(0,"VAN ") or s.has(0,"VON ") or s.has(0,"SCH") or s.has(i+1,"ET"): s.same("K")
    elif s.has(i+1,"IER "): s.same("J")
    else: s.choice("J","K")
    return i+2
  s.same("K")
  i + (if s.at(i+1)==uint8('G'): 2 else: 1)

proc ruleJ(s: var Encoder, i: int, germanic: bool): int =
  if s.has(i,"JOSE") or s.has(0,"SAN "):
    if (i==0 and s.at(i+4)==uint8(' ')) or s.has(0,"SAN "): s.same("H")
    else: s.choice("J","H")
    return i+1
  if i==0: s.choice("J","A")
  elif s.vowel(i-1) and not germanic and s.at(i+1) in [uint8('A'),uint8('O')]: s.choice("J","H")
  elif i==s.length-1: s.choice("J"," ")
  elif s.at(i+1) notin [uint8('L'),uint8('T'),uint8('K'),uint8('S'),uint8('N'),uint8('M'),uint8('B'),uint8('Z')] and
      s.at(i-1) notin [uint8('S'),uint8('K'),uint8('L')]: s.same("J")
  i + (if s.at(i+1)==uint8('J'): 2 else: 1)

proc ruleL(s: var Encoder, i: int): int =
  if s.at(i+1)!=uint8('L'): s.same("L"); return i+1
  let n=s.length
  let spanish=(i==n-3 and (s.has(i-1,"ILLO") or s.has(i-1,"ILLA") or s.has(i-1,"ALLE"))) or
    ((s.has(n-3,"AS") or s.has(n-3,"OS") or s.at(n-1)==uint8('A') or s.at(n-1)==uint8('O')) and s.has(i-1,"ALLE"))
  if spanish: s.choice("L"," ") else: s.same("L")
  i+2

proc ruleS(s: var Encoder, i: int, germanic: bool): int =
  if s.has(i-1,"ISL") or s.has(i-1,"YSL"): return i+1
  if i==0 and s.has(i,"SUGAR"): s.choice("X","S"); return i+1
  if s.has(i,"SH"):
    if s.has(i+1,"HEIM") or s.has(i+1,"HOEK") or s.has(i+1,"HOLM") or s.has(i+1,"HOLZ"): s.same("S")
    else: s.same("X")
    return i+2
  if s.has(i,"SIO") or s.has(i,"SIA") or s.has(i,"SIAN"):
    if not germanic: s.choice("S","X") else: s.same("S")
    return i+3
  if (i==0 and s.at(i+1) in [uint8('M'),uint8('N'),uint8('L'),uint8('W')]) or s.at(i+1)==uint8('Z'):
    s.choice("S","X"); return i+(if s.at(i+1)==uint8('Z'): 2 else: 1)
  if s.has(i,"SC"):
    if s.at(i+2)==uint8('H'):
      if s.has(i+3,"OO") or s.has(i+3,"ER") or s.has(i+3,"EN") or s.has(i+3,"UY") or s.has(i+3,"ED") or s.has(i+3,"EM"):
        if s.has(i+3,"ER") or s.has(i+3,"EN"): s.choice("X","SK") else: s.same("SK")
      elif i==0 and not s.vowel(3) and s.at(3)!=uint8('W'): s.choice("X","S")
      else: s.same("X")
      return i+3
    if s.at(i+2) in [uint8('I'),uint8('E'),uint8('Y')]: s.same("S") else: s.same("SK")
    return i+3
  if i==s.length-1 and (s.has(i-2,"AI") or s.has(i-2,"OI")): s.choice("","S")
  else: s.same("S")
  i+(if s.at(i+1) in [uint8('S'),uint8('Z')]: 2 else: 1)

proc ruleT(s: var Encoder, i: int): int =
  if s.has(i,"TION"): s.same("X"); return i+3
  if s.has(i,"TIA") or s.has(i,"TCH"): s.same("X"); return i+3
  if s.has(i,"TH") or s.has(i,"TTH"):
    if s.has(i+2,"OM") or s.has(i+2,"AM") or s.has(0,"VAN ") or s.has(0,"VON ") or s.has(0,"SCH"): s.same("T")
    else: s.choice("0","T")
    return i+2
  s.same("T")
  i+(if s.at(i+1) in [uint8('T'),uint8('D')]: 2 else: 1)

proc ruleW(s: var Encoder, i: int): int =
  if s.has(i,"WR"): s.same("R"); return i+2
  if i==0 and (s.vowel(i+1) or s.has(i,"WH")):
    if s.vowel(i+1): s.choice("A","F") else: s.same("A")
  if (i==s.length-1 and s.vowel(i-1)) or s.has(i-1,"EWSKI") or s.has(i-1,"EWSKY") or
      s.has(i-1,"OWSKI") or s.has(i-1,"OWSKY") or s.has(0,"SCH"):
    s.choice("","F"); return i+1
  if s.has(i,"WICZ") or s.has(i,"WITZ"): s.choice("TS","FX"); return i+4
  i+1

proc upperByte(value: int64): uint8 =
  if value>=ord('a') and value<=ord('z'): return uint8(value-(ord('a')-ord('A')))
  if value==0xE7: return 0xC7'u8
  if value==0xF1: return 0xD1'u8
  uint8(value)

proc double_metaphone*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc:"double_metaphone".} =
  if input.isNil or length < csize_t(1) or length > csize_t(34): return -1
  if input[0] < 0 or input[0] > TextLimit: return -1
  let count=int(input[0])
  if int(length)!=count+1: return -1
  var s: Encoder
  for i in 0 ..< TextLimit + Pad: s.text[i] = uint8(' ')
  s.length=count
  for i in 0..<count:
    let raw=input[i+1]
    if not ((raw>=ord('A') and raw<=ord('Z')) or (raw>=ord('a') and raw<=ord('z')) or raw==ord(' ') or
      raw==0xC7 or raw==0xE7 or raw==0xD1 or raw==0xF1): return -1
    s.text[i]=upperByte(raw)
  let germanic=s.slavo()
  var i=0
  if s.has(0,"GN") or s.has(0,"KN") or s.has(0,"PN") or s.has(0,"WR") or s.has(0,"PS"): i=1
  if s.at(0)==uint8('X'): s.same("S"); i=1
  while i<s.length and (s.primaryLen<KeyLimit or s.secondaryLen<KeyLimit):
    case s.at(i)
    of uint8('A'),uint8('E'),uint8('I'),uint8('O'),uint8('U'),uint8('Y'):
      if i==0: s.same("A")
      inc i
    of uint8('B'): s.same("P"); i+=(if s.at(i+1)==uint8('B'): 2 else: 1)
    of 0xC7'u8: s.same("S"); inc i
    of uint8('C'): i=s.ruleC(i)
    of uint8('D'):
      if s.has(i,"DG"):
        if s.at(i+2) in [uint8('I'),uint8('E'),uint8('Y')]: s.same("J"); i+=3
        else: s.same("TK"); i+=2
      elif s.has(i,"DT") or s.has(i,"DD"): s.same("T"); i+=2
      else: s.same("T"); inc i
    of uint8('F'): s.same("F"); i+=(if s.at(i+1)==uint8('F'): 2 else: 1)
    of uint8('G'): i=s.ruleG(i,germanic)
    of uint8('H'):
      if (i==0 or s.vowel(i-1)) and s.vowel(i+1): s.same("H"); i+=2
      else: inc i
    of uint8('J'): i=s.ruleJ(i,germanic)
    of uint8('K'): s.same("K"); i+=(if s.at(i+1)==uint8('K'): 2 else: 1)
    of uint8('L'): i=s.ruleL(i)
    of uint8('M'):
      if (s.has(i-1,"UMB") and (i+1==s.length-1 or s.has(i+2,"ER"))) or s.at(i+1)==uint8('M'): i+=2
      else: inc i
      s.same("M")
    of uint8('N'): s.same("N"); i+=(if s.at(i+1)==uint8('N'): 2 else: 1)
    of 0xD1'u8: s.same("N"); inc i
    of uint8('P'):
      if s.at(i+1)==uint8('H'): s.same("F"); i+=2
      else: s.same("P"); i+=(if s.at(i+1) in [uint8('P'),uint8('B')]: 2 else: 1)
    of uint8('Q'): s.same("K"); i+=(if s.at(i+1)==uint8('Q'): 2 else: 1)
    of uint8('R'):
      if i==s.length-1 and not germanic and s.has(i-2,"IE") and not s.has(i-4,"ME") and not s.has(i-4,"MA"): s.choice("","R")
      else: s.same("R")
      i+=(if s.at(i+1)==uint8('R'): 2 else: 1)
    of uint8('S'): i=s.ruleS(i,germanic)
    of uint8('T'): i=s.ruleT(i)
    of uint8('V'): s.same("F"); i+=(if s.at(i+1)==uint8('V'): 2 else: 1)
    of uint8('W'): i=s.ruleW(i)
    of uint8('X'):
      let french=i==s.length-1 and (s.has(i-3,"IAU") or s.has(i-3,"EAU") or s.has(i-2,"AU") or s.has(i-2,"OU"))
      if not french: s.same("KS")
      i+=(if s.at(i+1) in [uint8('C'),uint8('X')]: 2 else: 1)
    of uint8('Z'):
      if s.at(i+1)==uint8('H'): s.same("J"); i+=2
      else:
        if s.has(i+1,"ZO") or s.has(i+1,"ZI") or s.has(i+1,"ZA") or (germanic and i>0 and s.at(i-1)!=uint8('T')): s.choice("S","TS")
        else: s.same("S")
        i+=(if s.at(i+1)==uint8('Z'): 2 else: 1)
    else: inc i
  var secondLen=if s.alternateSeen: s.secondaryLen else: 0
  if secondLen==s.primaryLen and secondLen==s.secondaryLen:
    var identical=true
    for j in 0..<s.primaryLen:
      if s.primary[j]!=s.secondary[j]: identical=false
    if identical: secondLen=0
  let required=2+s.primaryLen+secondLen
  if output.isNil or capacity<csize_t(required): return -2
  output[0]=uint8(s.primaryLen); output[1]=uint8(secondLen)
  for j in 0..<s.primaryLen: output[j+2]=s.primary[j]
  for j in 0..<secondLen: output[j+2+s.primaryLen]=s.secondary[j]
  int64(required)
