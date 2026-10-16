import math

const MaxBatch = 8
const MaxTime = 16
const MaxVocab = 16
const MaxInputLength = 3 + MaxBatch * MaxTime * (MaxVocab + 1)
const InvalidResult = -1.0e300

proc perplexity_loss*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "perplexity_loss".} =
  if values == nil or length < 3 or length > MaxInputLength: return InvalidResult
  let batchValue = values[0]
  let timeValue = values[1]
  let vocabValue = values[2]
  if batchValue < 1 or batchValue > MaxBatch or timeValue < 1 or timeValue > MaxTime or
      vocabValue < 2 or vocabValue > MaxVocab: return InvalidResult
  let batch = int(batchValue)
  let time = int(timeValue)
  let vocab = int(vocabValue)
  let tokens = batch * time
  let probabilityBase = 3 + tokens
  if length != csize_t(probabilityBase + tokens * vocab): return InvalidResult
  for row in 0 ..< tokens:
    let label = values[3 + row]
    if label < 0 or label >= int64(vocab): return InvalidResult
    var rowSum: int64 = 0
    for c in 0 ..< vocab:
      let p = values[probabilityBase + row * vocab + c]
      if p < 0 or p > 1_000_000: return InvalidResult
      rowSum += p
    if rowSum != 1_000_000: return InvalidResult
  var batchTotal = 0.0
  for sentence in 0 ..< batch:
    var logTotal = 0.0
    for step in 0 ..< time:
      let row = sentence * time + step
      let label = int(values[3 + row])
      var probability = float64(values[probabilityBase + row * vocab + label]) / 1_000_000.0
      if probability < 1e-7: probability = 1e-7
      if probability > 1.0: probability = 1.0
      logTotal += ln(probability)
    batchTotal += exp(-(logTotal / float64(time)))
  batchTotal / float64(batch)
