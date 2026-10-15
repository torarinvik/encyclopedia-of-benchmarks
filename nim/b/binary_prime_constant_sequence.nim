const MaxCount = 4096

type
  I64Input = ptr UncheckedArray[int64]
  ByteOutput = ptr UncheckedArray[uint8]

proc isPrime(candidate: int64): bool =
  if candidate < 2: return false
  var divisor = 2'i64
  while divisor <= candidate div divisor:
    if candidate mod divisor == 0: return false
    inc divisor
  true

proc binary_prime_constant_sequence*(input: I64Input, length: csize_t,
                                     output: ByteOutput, outputCapacity: csize_t): int64
    {.cdecl, exportc: "binary_prime_constant_sequence".} =
  if input.isNil or length != 1 or input[0] < 0 or input[0] > MaxCount: return -1
  let count = int(input[0])
  if outputCapacity < csize_t(count) or (count > 0 and output.isNil): return -2

  var next = 1
  var candidate = 2'i64
  while candidate <= input[0]:
    if isPrime(candidate):
      while next < int(candidate):
        output[next - 1] = 0
        inc next
      output[int(candidate) - 1] = 1
      next = int(candidate) + 1
    inc candidate
  while next <= count:
    output[next - 1] = 0
    inc next
  int64(count)
