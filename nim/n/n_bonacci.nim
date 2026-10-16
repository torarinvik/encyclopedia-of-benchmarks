## Return the final term of a bounded N-bonacci sequence.
proc n_bonacci*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "n_bonacci".} =
  if values.isNil or length != 2: return -1
  let orderValue = values[0]
  let countValue = values[1]
  if orderValue < 1 or countValue <= orderValue or countValue > 64: return -1
  let order = int(orderValue)
  let count = int(countValue)
  var terms: array[64, int64]
  terms[order - 1] = 1
  terms[order] = 1
  for index in order + 1 ..< count:
    terms[index] = 2 * terms[index - 1] - terms[index - 1 - order]
  terms[count - 1]
