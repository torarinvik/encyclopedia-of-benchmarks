proc multiplexer*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "multiplexer".} =
  if values == nil or length != 3: return -1
  let input0 = values[0]
  let input1 = values[1]
  let select = values[2]
  if (input0 != 0 and input0 != 1) or (input1 != 0 and input1 != 1) or
      (select != 0 and select != 1): return -1
  if select == 1: return input1
  input0
