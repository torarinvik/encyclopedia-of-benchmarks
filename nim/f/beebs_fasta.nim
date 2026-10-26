## Clean-room, bounded BEEBS FASTA generation profile.
const
  MaxCount = 1000'i64
  MaxState = 139967'i64
  Width = 60
  Alu = "GGCCGGGCGCGGTGGCTCACGCCTGTAATCCCAGCACTTTGG" &
        "GAGGCCGAGGCGGGCGGATCACCTGAGGTCAGGAGTTCGAGA" &
        "CCAGCCTGGCCAACATGGTGAAACCCCGTCTCTACTAAAAAT" &
        "ACAAAAATTAGCCGGGCGTGGTGGCGCGCGCCTGTAATCCCA" &
        "GCTACTCGGGAGGCTGAGGCAGGAGAATCGCTTGAACCCGGG" &
        "AGGCGGAGGTTGCAGTGAGCCGAGATCGCGCCACTGCACTCC" &
        "AGCCTGGGCGACAGAGCGAGACTCCGTCTCAAAAA"
  IubWeights: array[15, float32] = [0.27'f32, 0.12'f32, 0.12'f32, 0.27'f32,
    0.02'f32, 0.02'f32, 0.02'f32, 0.02'f32, 0.02'f32, 0.02'f32,
    0.02'f32, 0.02'f32, 0.02'f32, 0.02'f32, 0.02'f32]
  IubSymbols: array[15, uint8] = [97'u8, 99'u8, 103'u8, 116'u8, 66'u8, 68'u8,
    72'u8, 75'u8, 77'u8, 78'u8, 82'u8, 83'u8, 86'u8, 87'u8, 89'u8]
  HumanWeights: array[4, float32] = [0.3029549426680'f32, 0.1979883004921'f32,
    0.1975473066391'f32, 0.3015094502008'f32]
  HumanSymbols: array[4, uint8] = [97'u8, 99'u8, 103'u8, 116'u8]

proc wrappedLines(count: int): int = (count + Width - 1) div Width

proc fastaOutputLength(count: int): int =
  77 + 10 * count + wrappedLines(2 * count) + wrappedLines(3 * count) + wrappedLines(5 * count)

proc accumulateProbabilities(weights: var openArray[float32]) =
  var cumulative = 0.0'f32
  for weight in weights.mitems:
    cumulative += weight
    weight = cumulative

proc nextWeightedBase(state: var uint32, weights: openArray[float32],
                      symbols: openArray[uint8]): uint8 =
  state = (state * 3877'u32 + 29573'u32) mod 139968'u32
  let randomValue = 1.0'f32 * float32(state) / 139968.0'f32
  for i in 0 ..< weights.len:
    if weights[i] >= randomValue: return symbols[i]
  symbols[^1]

proc writeRepeat(output: ptr UncheckedArray[uint8], offset: int, count: int): int =
  result = offset
  for i in 0 ..< count:
    output[result] = uint8(ord(Alu[i mod Alu.len]))
    inc result
    if (i + 1) mod Width == 0 or i + 1 == count:
      output[result] = 10'u8
      inc result

proc writeWeighted(output: ptr UncheckedArray[uint8], offset: int, count: int,
                   state: var uint32, weights: openArray[float32],
                   symbols: openArray[uint8]): int =
  result = offset
  for i in 0 ..< count:
    output[result] = nextWeightedBase(state, weights, symbols)
    inc result
    if (i + 1) mod Width == 0 or i + 1 == count:
      output[result] = 10'u8
      inc result

proc beebs_fasta*(values: ptr UncheckedArray[int64], length: csize_t,
                  output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "beebs_fasta".} =
  if values.isNil or length != 2: return -1
  let countValue = values[0]
  let seedValue = values[1]
  if countValue < 1 or countValue > MaxCount or seedValue < 0 or seedValue > MaxState: return -1
  let count = int(countValue)
  let needed = fastaOutputLength(count)
  if output.isNil or capacity < csize_t(needed): return -2
  var iubWeights = IubWeights
  var humanWeights = HumanWeights
  accumulateProbabilities(iubWeights)
  accumulateProbabilities(humanWeights)
  let headerOne = ">ONE Homo sapiens alu\n"
  let headerTwo = ">TWO IUB ambiguity codes\n"
  let headerThree = ">THREE Homo sapiens frequency\n"
  var offset = 0
  for ch in headerOne:
    output[offset] = uint8(ord(ch))
    inc offset
  offset = writeRepeat(output, offset, 2 * count)
  for ch in headerTwo:
    output[offset] = uint8(ord(ch))
    inc offset
  var state = uint32(seedValue)
  offset = writeWeighted(output, offset, 3 * count, state, iubWeights, IubSymbols)
  for ch in headerThree:
    output[offset] = uint8(ord(ch))
    inc offset
  offset = writeWeighted(output, offset, 5 * count, state, humanWeights, HumanSymbols)
  int64(offset)
