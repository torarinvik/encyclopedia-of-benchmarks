proc federated_averaging*(input: ptr UncheckedArray[int64], length: csize_t): float64 {.cdecl, exportc: "federated_averaging".} =
  const invalidResult = -1.0e300
  if input == nil or length < 3 or length > 17: return invalidResult
  let clients = input[0]
  if clients < 1 or clients > 8 or length != csize_t(1 + 2 * clients): return invalidResult
  var total = 0.0
  for i in 0..<int(clients):
    let weight = input[1 + i]
    if weight < 0 or weight > 1000: return invalidResult
    total += float64(weight)
  if total <= 0.0: return invalidResult
  var result = 0.0
  for i in 0..<int(clients):
    let value = input[1 + int(clients) + i]
    if value < -1000 or value > 1000: return invalidResult
    let normalized = float64(input[1 + i]) / total
    result += normalized * float64(value)
  result
