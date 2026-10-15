proc number_of_boolean_functions_sequence*(index: int64): int64 {.cdecl, exportc: "number_of_boolean_functions_sequence".} =
  if index < 0 or index > 5: return -1
  var value = 2'i64
  var i = 0'i64
  while i < index:
    value *= value
    i += 1
  return value
