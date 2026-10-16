const MaxNumber = 4096'i64
const StackCapacity = 4112

proc lexicographical_numbers*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "lexicographical_numbers".} =
  if values == nil or length != 1 or values[0] < 0 or values[0] > MaxNumber: return -1
  var stack: array[StackCapacity, int64]
  var top = 1
  stack[0] = 1
  var index = 0'i64
  var checksum = 0'i64
  while top > 0:
    dec top
    let number = stack[top]
    if number <= values[0]:
      inc index
      checksum += index * number
      if number mod 10 != 9:
        stack[top] = number + 1
        inc top
      stack[top] = number * 10
      inc top
  checksum
