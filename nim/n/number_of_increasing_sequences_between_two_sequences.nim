## Clean-room bounded implementation of the Library Checker sequence-counting task.

const MaxN = 64
const MaxM = 64
const MaxInputLength = 130
const Modulus = 998244353'i64

proc number_of_increasing_sequences_between_two_sequences*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "number_of_increasing_sequences_between_two_sequences".} =
  if input.isNil or length < 4 or length > MaxInputLength: return -1
  if input[0] < 1 or input[0] > MaxN or input[1] < 1 or input[1] > MaxM: return -1
  let n = int(input[0])
  let m = int(input[1])
  if int(length) != 2 + 2 * n: return -1
  var lower: array[MaxN, int64]
  var upper: array[MaxN, int64]
  for i in 0 ..< n:
    lower[i] = input[2 + i]
    upper[i] = input[2 + n + i]
    if lower[i] < 0 or lower[i] >= upper[i] or upper[i] > int64(m): return -1
  var previous: array[MaxM, int64]
  var current: array[MaxM, int64]
  for value in int(lower[0]) ..< int(upper[0]): previous[value] = 1
  for position in 1 ..< n:
    var prefix = 0'i64
    for value in 0 ..< m:
      prefix += previous[value]
      if prefix >= Modulus: prefix -= Modulus
      if lower[position] <= int64(value) and int64(value) < upper[position]:
        current[value] = prefix
      else:
        current[value] = 0
    swap(previous, current)
  var answer = 0'i64
  for value in 0 ..< m:
    answer += previous[value]
    if answer >= Modulus: answer -= Modulus
  answer
