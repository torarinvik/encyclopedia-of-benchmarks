## Return the next larger positive integer with the same population count.
proc next_higher_number_with_same_number_of_set_bits*(input: int64): int64
    {.cdecl, exportc: "next_higher_number_with_same_number_of_set_bits".} =
  if input < 1 or input > 1_073_741_823: return -1
  let rightOne = input and -input
  let nextHigher = input + rightOne
  var packedOnes = (input xor nextHigher) div rightOne
  packedOnes = packedOnes shr 2
  nextHigher or packedOnes
