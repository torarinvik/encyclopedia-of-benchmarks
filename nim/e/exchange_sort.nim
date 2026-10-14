## In-place exchange sort for the shared sorting contract.
proc exchange_sort*(values: ptr UncheckedArray[int64], length: csize_t) {.cdecl, exportc: "exchange_sort".} =
  if length < 2:
    return
  let last = length - 1
  for first in 0 ..< last:
    var other = first + 1
    while other < length:
      if values[other] < values[first]:
        let temporary = values[first]
        values[first] = values[other]
        values[other] = temporary
      inc other
