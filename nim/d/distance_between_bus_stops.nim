## Sum both circular routes and return the shorter one.
proc distance_between_bus_stops*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "distance_between_bus_stops".} =
  if length < 3 or length > 66: return -1
  let stopCount = int(length) - 2
  let startValue = input[0]
  let destinationValue = input[1]
  if startValue < 0 or destinationValue < 0 or
      startValue >= int64(stopCount) or destinationValue >= int64(stopCount):
    return -1
  let start = int(startValue)
  let destination = int(destinationValue)
  let low = min(start, destination)
  let high = max(start, destination)
  var total = 0'i64
  var direct = 0'i64
  for index in 0 ..< stopCount:
    let distance = input[index + 2]
    if distance < 0 or distance > 1_000_000: return -1
    total += distance
    if index >= low and index < high:
      direct += distance
  let other = total - direct
  min(direct, other)
