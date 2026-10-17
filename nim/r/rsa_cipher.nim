proc rsa_cipher_encrypt_ascii*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "rsa_cipher_encrypt_ascii".} =
  if values == nil or length != 3: return -1
  let asciiCode = values[0]
  let exponentInput = values[1]
  let modulus = values[2]
  if asciiCode < 0 or asciiCode > 127 or modulus < 128 or modulus > 65_535 or
      exponentInput < 1 or exponentInput >= modulus: return -1

  var base = uint64(asciiCode)
  var exponent = uint64(exponentInput)
  let unsignedModulus = uint64(modulus)
  var result = 1'u64
  base = base mod unsignedModulus
  while exponent > 0:
    if exponent mod 2 == 1:
      result = (result * base) mod unsignedModulus
    exponent = exponent shr 1
    base = (base * base) mod unsignedModulus
  int64(result)
