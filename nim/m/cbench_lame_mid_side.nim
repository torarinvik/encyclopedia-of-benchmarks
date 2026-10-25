import std/math

const MaxSamples = 32
const MaxInput = 65
const MaxOutput = 64
const Sqrt2 = 1.414213562373095048801688724209698079

proc cbench_lame_mid_side*(input: ptr UncheckedArray[float64], n: csize_t,
    output: ptr UncheckedArray[float64], cap: csize_t): int64 {.cdecl, exportc: "cbench_lame_mid_side".} =
  if input == nil or n < 1 or n > (MaxInput+1).csize_t: return -1
  for i in 0 ..< int(n):
    if classify(input[i]) in {fcNan, fcInf, fcNegInf}: return -1
  if input[0] < 1.0 or input[0] > MaxSamples.float64 or input[0] != trunc(input[0]): return -1
  let count = int(input[0])
  if n != (1+2*count).csize_t: return -1
  for i in 1 ..< int(n):
    if input[i] < -16.0 or input[i] > 16.0: return -1
  var staged: array[MaxOutput, float64]
  let factor = Sqrt2 * 0.5
  for i in 0 ..< count:
    let left=input[1+i]; let right=input[1+count+i]
    staged[2*i]=(left+right)*factor
    staged[2*i+1]=(left-right)*factor
  let needed=2*count
  if output == nil or cap < needed.csize_t: return -2
  for i in 0 ..< needed: output[i]=staged[i]
  needed.int64
