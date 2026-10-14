const MaxOperations = 256
const DimensionLimit = 1000'i64
const ResultOffset = 1_000_000_007'i64

proc integerSqrt(value: int64): int64 =
  var low = 0'i64
  var high = 3_037_000_499'i64
  var answer = 0'i64
  while low <= high:
    let middle = low + (high - low) div 2
    if middle == 0 or middle <= value div middle:
      answer = middle
      low = middle + 1
    else:
      high = middle - 1
  answer

proc scalePi(value: int64): int64 =
  value * 3 + value * 141_592_654 div 1_000_000_000

proc scalePiSquared(value: int64): int64 =
  value * 9 + value * 869_604_401 div 1_000_000_000

proc regularPolygonCoefficient(sides: int64): int64 =
  case sides
  of 3: 433_012_701
  of 4: 1_000_000_000
  of 5: 1_720_477_400
  of 6: 2_598_076_211
  of 7: 3_633_912_444
  of 8: 4_828_427_124
  of 9: 6_181_824_193
  of 10: 7_694_208_842
  of 11: 9_365_639_906
  of 12: 11_196_152_422
  of 13: 13_185_768_328
  of 14: 15_334_501_936
  of 15: 17_642_362_910
  of 16: 20_109_357_968
  of 17: 22_735_491_898
  of 18: 25_520_768_188
  of 19: 28_465_189_427
  of 20: 31_568_757_573
  of 21: 34_831_474_123
  of 22: 38_253_340_244
  of 23: 41_834_356_852
  of 24: 45_574_524_676
  of 25: 49_473_844_301
  of 26: 53_532_316_204
  of 27: 57_749_940_771
  of 28: 62_126_718_324
  of 29: 66_662_649_129
  of 30: 71_357_733_406
  of 31: 76_211_971_344
  of 32: 81_225_363_100
  else: -1

proc areaMilli(operation, a, b, c: int64): int64 =
  case operation
  of 0: a * a * 1000
  of 1: a * b * 1000
  of 2: a * b * 500
  of 3: scalePi(a * a * 1000)
  of 4: a * b * 1000
  of 5: (a + b) * c * 500
  of 6:
    let perimeter = a + b + c
    if a + b < c or a + c < b or b + c < a: return -1
    let radicand = perimeter * (perimeter - 2 * a) * (perimeter - 2 * b) * (perimeter - 2 * c)
    integerSqrt(radicand * 1_000_000) div 4
  of 7: scalePi(a * b * 1000)
  of 8: a * b * 500
  of 9: 6 * a * a * 1000
  of 10: 2 * (a * b + a * c + b * c) * 1000
  of 11: scalePi(4 * a * a * 1000)
  of 12: scalePi(3 * a * a * 1000)
  of 13: scalePi(2 * a * (b + a) * 1000)
  of 14: scalePi(2 * a * b * 1000)
  of 15:
    let slantMilli = integerSqrt((a * a + b * b) * 1_000_000)
    scalePi(a * a * 1000 + a * slantMilli)
  of 16:
    let slantMilli = integerSqrt((a * a + b * b) * 1_000_000)
    scalePi(a * slantMilli)
  of 17: (a * a + 2 * a * b) * 1000
  of 18:
    let difference = if a >= b: a - b else: b - a
    let slantMilli = integerSqrt((c * c + difference * difference) * 1_000_000)
    scalePi((a * a + b * b) * 1000 + (a + b) * slantMilli)
  of 19: scalePiSquared(4 * a * b * 1000)
  of 20:
    let coefficient = regularPolygonCoefficient(a)
    if coefficient < 0: return -1
    coefficient * b * b div 1_000_000
  of 21:
    let coefficient = regularPolygonCoefficient(a)
    if coefficient < 0: return -1
    2 * (coefficient * b * b div 1_000_000) + a * b * c * 1000
  else: -1

proc area_benchmark*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "area_benchmark".} =
  if length < 1 or length > 1025: return -1
  let countValue = values[0]
  if countValue < 0 or countValue > MaxOperations.int64 or length.int != 1 + 4 * countValue.int: return -1
  var checksum = 0'i64
  for index in 0 ..< countValue.int:
    let position = 1 + 4 * index
    let operation = values[position]
    let a = values[position + 1]
    let b = values[position + 2]
    let c = values[position + 3]
    if (operation < 0 or operation > 21 or a < 0 or a > DimensionLimit or
        b < 0 or b > DimensionLimit or c < 0 or c > DimensionLimit): return -1
    if ((operation == 0 or operation == 3 or operation == 9 or operation == 11 or operation == 12) and
        (b != 0 or c != 0)): return -1
    if (((operation >= 1 and operation <= 2) or operation == 4 or (operation >= 7 and operation <= 8) or
        (operation >= 13 and operation <= 17) or operation == 19 or operation == 20) and c != 0): return -1
    let result = areaMilli(operation, a, b, c)
    if result < 0: return -1
    checksum += (index.int64 + 1) * (result + ResultOffset)
  checksum
