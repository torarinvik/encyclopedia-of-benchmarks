import std/math

const MaxInput = 2054
const MaxAudio = 2048
const MaxFft = 1024
const MaxFrames = 257
const MaxMels = 16
const MaxDcts = 40
const Pi = 3.14159265358979323846264338327950288

proc fft(real, imag: var array[MaxFft, float64], n: int) =
  var reversed = 0
  for position in 1 ..< n:
    var bit = n shr 1
    while (reversed and bit) != 0:
      reversed = reversed xor bit
      bit = bit shr 1
    reversed = reversed xor bit
    if position < reversed:
      swap(real[position], real[reversed])
      swap(imag[position], imag[reversed])
  var blockSize = 2
  while blockSize <= n:
    let angle = -2.0 * Pi / float64(blockSize)
    let stepReal = cos(angle)
    let stepImag = sin(angle)
    let half = blockSize shr 1
    var start = 0
    while start < n:
      var weightReal = 1.0
      var weightImag = 0.0
      for offset in 0 ..< half:
        let even = start + offset
        let odd = even + half
        let productReal = weightReal * real[odd] - weightImag * imag[odd]
        let productImag = weightReal * imag[odd] + weightImag * real[odd]
        real[odd] = real[even] - productReal
        imag[odd] = imag[even] - productImag
        real[even] += productReal
        imag[even] += productImag
        let nextReal = weightReal * stepReal - weightImag * stepImag
        weightImag = weightReal * stepImag + weightImag * stepReal
        weightReal = nextReal
      start += blockSize
    blockSize = blockSize shl 1

proc hzToMel(hz: float64): float64 = 2595.0 * log10(1.0 + hz / 700.0)
proc melToHz(mel: float64): float64 = 700.0 * (pow(10.0, mel / 2595.0) - 1.0)

proc putF64Le(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8(bits and 255'u64)
    bits = bits shr 8

proc mfcc*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "mfcc".} =
  if input.isNil or length < 6 or length > csize_t(MaxInput): return -1
  let countValue = input[0]
  let sampleRateValue = input[1]
  let hopMsValue = input[2]
  let fftValue = input[3]
  let melValue = input[4]
  let dctValue = input[5]
  if countValue < 33 or countValue > int64(MaxAudio) or length != csize_t(countValue + 6): return -1
  if sampleRateValue < 8000 or sampleRateValue > 48000 or hopMsValue < 1 or hopMsValue > 50: return -1
  if fftValue != 64 and fftValue != 128 and fftValue != 256 and fftValue != 512 and fftValue != 1024: return -1
  if melValue < 2 or melValue > int64(MaxMels) or dctValue < 1 or dctValue > int64(MaxDcts): return -1

  let count = int(countValue)
  let sampleRate = int(sampleRateValue)
  let fftSize = int(fftValue)
  let melCount = int(melValue)
  let dctCount = int(dctValue)
  if count < fftSize div 2 + 1: return -1
  let hopNumerator = sampleRate * int(hopMsValue)
  var hop = hopNumerator div 1000
  let hopRemainder = hopNumerator mod 1000
  if hopRemainder > 500 or (hopRemainder == 500 and hop mod 2 == 1): inc hop
  if hop < 1: return -1

  var audio: array[MaxAudio, float64]
  var peak = 0.0
  for index in 0 ..< count:
    let sample = cast[float64](cast[uint64](input[6 + index]))
    if sample != sample or abs(sample) > 1_000_000.0: return -1
    audio[index] = sample
    peak = max(peak, abs(sample))
  if peak == 0.0: return -1
  for index in 0 ..< count: audio[index] /= peak

  let pad = fftSize div 2
  let frames = count div hop + 1
  let binCount = fftSize div 2 + 1
  if frames > MaxFrames: return -1
  var padded: array[MaxAudio + MaxFft, float64]
  for index in 0 ..< pad: padded[index] = audio[pad - index]
  for index in 0 ..< count: padded[pad + index] = audio[index]
  for index in 0 ..< pad: padded[pad + count + index] = audio[count - 2 - index]

  var frequencies: array[MaxMels + 2, float64]
  var bins: array[MaxMels + 2, int]
  let melLow = hzToMel(0.0)
  let melHigh = hzToMel(float64(sampleRate div 2))
  for index in 0 ..< melCount + 2:
    let mel = melLow + (melHigh - melLow) * float64(index) / float64(melCount + 1)
    frequencies[index] = melToHz(mel)
    let bin = floor(float64(fftSize + 1) / float64(sampleRate) * frequencies[index])
    if bin < 0.0 or bin >= float64(binCount): return -1
    bins[index] = int(bin)
  for index in 0 ..< melCount + 1:
    if bins[index] >= bins[index + 1]: return -1
  var norms: array[MaxMels, float64]
  for index in 0 ..< melCount:
    norms[index] = 2.0 / (frequencies[index + 2] - frequencies[index])
    if norms[index] != norms[index]: return -1

  var window: array[MaxFft, float64]
  for index in 0 ..< fftSize:
    window[index] = 0.5 - 0.5 * cos(2.0 * Pi * float64(index) / float64(fftSize))
  var logged: array[MaxMels, array[MaxFrames, float64]]
  for frame in 0 ..< frames:
    var real: array[MaxFft, float64]
    var imag: array[MaxFft, float64]
    for index in 0 ..< fftSize: real[index] = padded[frame * hop + index] * window[index]
    fft(real, imag, fftSize)
    var power: array[MaxFft div 2 + 1, float32]
    for index in 0 ..< binCount:
      let real32 = float32(real[index])
      let imag32 = float32(imag[index])
      let magnitude = float32(sqrt(float64(real32 * real32 + imag32 * imag32)))
      power[index] = magnitude * magnitude
    for filterIndex in 0 ..< melCount:
      let first = bins[filterIndex]
      let middle = bins[filterIndex + 1]
      let last = bins[filterIndex + 2]
      let rise = middle - first
      let fall = last - middle
      var energy = 0.0
      for index in first ..< middle:
        let weight = if rise == 1: 0.0 else: float64(index - first) / float64(rise - 1)
        energy += float64(power[index]) * weight
      for index in middle ..< last:
        let weight = if fall == 1: 1.0 else: 1.0 - float64(index - middle) / float64(fall - 1)
        energy += float64(power[index]) * weight
      energy *= norms[filterIndex]
      if energy <= 0.0 or energy != energy: return -1
      logged[filterIndex][frame] = 10.0 * log10(energy)

  var coefficients: array[MaxDcts, array[MaxFrames, float64]]
  for coefficient in 0 ..< dctCount:
    let scale = if coefficient == 0: 1.0 / sqrt(float64(melCount)) else: sqrt(2.0 / float64(melCount))
    for frame in 0 ..< frames:
      var total = 0.0
      for index in 0 ..< melCount:
        var basis = scale
        if coefficient != 0:
          basis = scale * cos(float64(coefficient) * (2.0 * float64(index) + 1.0) * Pi / (2.0 * float64(melCount)))
        total += basis * logged[index][frame]
      if total != total: return -1
      coefficients[coefficient][frame] = total

  let required = dctCount * frames * 8
  if output.isNil or capacity < csize_t(required): return -2
  for coefficient in 0 ..< dctCount:
    for frame in 0 ..< frames:
      putF64Le(output, (coefficient * frames + frame) * 8, coefficients[coefficient][frame])
  int64(required)
