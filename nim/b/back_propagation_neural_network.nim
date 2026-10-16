import std/math

const Scale = 1_000_000.0

proc quantize(value: float64): int64 =
  let scaled = value * Scale
  if scaled >= 0.0: int64(scaled + 0.5) else: int64(scaled - 0.5)

proc putI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (byte * 8)) and 255'u64)

proc back_propagation_neural_network*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "back_propagation_neural_network".} =
  if input.isNil or length != 7: return -1
  let xQ = input[0]
  let targetQ = input[1]
  let hiddenWeightQ = input[2]
  let hiddenBiasQ = input[3]
  let outputWeightQ = input[4]
  let outputBiasQ = input[5]
  let rateQ = input[6]
  if xQ < -1_000_000 or xQ > 1_000_000 or targetQ < -1_000_000 or targetQ > 1_000_000 or
      hiddenWeightQ < -2_000_000 or hiddenWeightQ > 2_000_000 or
      hiddenBiasQ < -2_000_000 or hiddenBiasQ > 2_000_000 or
      outputWeightQ < -2_000_000 or outputWeightQ > 2_000_000 or
      outputBiasQ < -2_000_000 or outputBiasQ > 2_000_000 or rateQ < 1 or rateQ > 300_000:
    return -1

  let x = float64(xQ) / Scale
  let target = float64(targetQ) / Scale
  let hiddenWeight = float64(hiddenWeightQ) / Scale
  let hiddenBias = float64(hiddenBiasQ) / Scale
  let outputWeight = float64(outputWeightQ) / Scale
  let outputBias = float64(outputBiasQ) / Scale
  let learningRate = float64(rateQ) / Scale
  let hiddenNet = hiddenWeight * x - hiddenBias
  let hidden = 1.0 / (1.0 + exp(-hiddenNet))
  let outputNet = outputWeight * hidden - outputBias
  let prediction = 1.0 / (1.0 + exp(-outputNet))
  let difference = target - prediction
  let loss = difference * difference
  let lossGradient = 2.0 * (prediction - target)
  let outputDelta = lossGradient * prediction * (1.0 - prediction)
  let outputWeightGradient = outputDelta * hidden
  let outputBiasGradient = -outputDelta
  let hiddenGradient = outputDelta * outputWeight
  let hiddenDelta = hiddenGradient * hidden * (1.0 - hidden)
  let hiddenWeightGradient = hiddenDelta * x
  let hiddenBiasGradient = -hiddenDelta
  let updatedHiddenWeight = hiddenWeight - learningRate * hiddenWeightGradient
  let updatedHiddenBias = hiddenBias - learningRate * hiddenBiasGradient
  let updatedOutputWeight = outputWeight - learningRate * outputWeightGradient
  let updatedOutputBias = outputBias - learningRate * outputBiasGradient

  if output.isNil or capacity < 56: return -2
  let result = [quantize(loss), quantize(hidden), quantize(prediction),
    quantize(updatedHiddenWeight), quantize(updatedHiddenBias),
    quantize(updatedOutputWeight), quantize(updatedOutputBias)]
  for index in 0 ..< 7: putI64Le(output, index * 8, result[index])
  56
