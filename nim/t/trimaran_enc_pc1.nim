# Pukall Cipher 1 adaptation; source author Alexander Pukall (1991), unrestricted use.
type State = object
  words: array[16, uint16]
  si, x1a2: uint16

const MaxNumInput = 2049'i64

proc codeStep(s: var State, index: int): uint16 =
  var dx = s.x1a2 +% uint16(index)
  var ax = s.words[index]
  var cx = 0x015a'u16
  let bx = 0x4e35'u16
  var tmp = ax
  ax = s.si; s.si = tmp; tmp = ax; ax = dx; dx = tmp
  if ax != 0: ax = ax *% bx
  tmp = ax; ax = cx; cx = tmp
  if ax != 0:
    ax = ax *% s.si
    cx = cx +% ax
  tmp = ax; ax = s.si; s.si = tmp
  ax = ax *% bx
  dx = dx +% cx
  ax = ax +% 1'u16
  s.x1a2 = dx; s.words[index] = ax
  ax xor dx

proc assemble(s: var State, key: array[32, uint8]): uint16 =
  s.words[0] = (uint16(key[0]) shl 8) or uint16(key[1])
  result = codeStep(s, 0)
  for i in 1 ..< 16:
    let word = (uint16(key[2*i]) shl 8) or uint16(key[2*i+1])
    s.words[i] = s.words[i-1] xor word
    result = result xor codeStep(s, i)

proc trimaran_enc_pc1*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "trimaran_enc_pc1".} =
  if input == nil or length != 1: return -1
  let count = input[0]
  if count < 1 or count > MaxNumInput: return -1
  var key: array[32, uint8]
  for i, ch in "abcdefghijklmnopqrstuvwxyz012345": key[i] = uint8(ord(ch))
  var state: State
  var seed = 1'u32
  var last = 0'u16
  for step in 0 ..< int(count - 1):
    seed = seed *% 1664525'u32 +% 1013904223'u32
    let plain = uint16((seed shr 16) and 0x7fff)
    let inter = assemble(state, key)
    let cipher = plain xor ((inter shr 8) xor (inter and 255))
    let feedback = uint8(plain and 255)
    for i in 0 ..< 32: key[i] = key[i] xor feedback
    last = cipher
  int64(last)
