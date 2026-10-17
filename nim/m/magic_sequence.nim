const MaxN = 11
const FnvOffsetBasis = 14_695_981_039_346_656_037'u64
const FnvPrime = 1_099_511_628_211'u64
const I64ResultMask = 0x7fff_ffff_ffff_ffff'u64

proc fnvByte(hash: var uint64, value: uint8) =
  hash = (hash xor uint64(value)) * FnvPrime

proc enumerate(n: int, hash: var uint64, hashRows: bool): uint32 =
  if n == 0: return 1

  var vector: array[MaxN, uint8]
  var frequencies: array[MaxN, uint8]
  var nextCandidate: array[MaxN, uint8]
  var prefixSum: array[MaxN + 1, uint8]
  var depth = 0
  var solutionCount = 0'u32

  while true:
    if depth == n:
      var isMagic = true
      for symbol in 0 ..< n:
        if frequencies[symbol] != vector[symbol]:
          isMagic = false
          break
      if isMagic:
        inc solutionCount
        if hashRows:
          for index in 0 ..< n:
            fnvByte(hash, vector[index])
      dec depth
      dec frequencies[int(vector[depth])]
      continue

    let candidate = nextCandidate[depth]
    if int(candidate) >= n:
      nextCandidate[depth] = 0
      if depth == 0: break
      dec depth
      dec frequencies[int(vector[depth])]
      continue
    nextCandidate[depth] = candidate + 1
    let sum = int(prefixSum[depth]) + int(candidate)
    if sum > n: continue

    vector[depth] = candidate
    inc frequencies[int(candidate)]
    prefixSum[depth + 1] = uint8(sum)
    inc depth
    nextCandidate[depth] = 0

  solutionCount

proc magic_sequence*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "magic_sequence".} =
  if input.isNil or length != 1: return -1
  let nValue = input[0]
  if nValue < 0 or nValue > MaxN: return -1
  let n = int(nValue)

  var hash = FnvOffsetBasis
  fnvByte(hash, uint8(n))
  let solutionCount = enumerate(n, hash, false)
  for shift in 0 ..< 4:
    fnvByte(hash, uint8((solutionCount shr (shift * 8)) and 0xff'u32))
  discard enumerate(n, hash, true)
  int64(hash and I64ResultMask)
