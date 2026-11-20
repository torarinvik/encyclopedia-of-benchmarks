type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]

const MaxTerms = 64
const MaxWords = 129

proc writeI64Le(output: U8Output, offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset+byte] = uint8((bits shr (byte*8)) and 255'u64)

proc hofstadter_figure_figure_sequences*(input: I64Input, length: csize_t,
    output: U8Output, outputCapacity: csize_t): int64 {.cdecl, exportc: "hofstadter_figure_figure_sequences".} =
  if input == nil or length == 0 or length > 2: return -1
  let nValue=input[0]
  if nValue < 1 or nValue > int64(MaxTerms) or length != 1: return -1
  let n=int(nValue)
  var figure: array[MaxTerms,int64]
  var space: array[MaxTerms,int64]
  figure[0]=1; space[0]=2
  var candidate=3'i64
  for i in 1 ..< n:
    figure[i]=figure[i-1]+space[i-1]
    var used=true
    while used:
      used=false
      for j in 0 .. i:
        if figure[j]==candidate: used=true
      if used: inc candidate
    space[i]=candidate
    inc candidate
  let wordCount=1+2*n
  let outputBytes=wordCount*8
  if output == nil or outputCapacity < csize_t(outputBytes): return -2
  var words: array[MaxWords,int64]
  words[0]=nValue
  for i in 0 ..< n:
    words[1+i]=figure[i]
    words[1+n+i]=space[i]
  for i in 0 ..< wordCount: writeI64Le(output,i*8,words[i])
  int64(outputBytes)
