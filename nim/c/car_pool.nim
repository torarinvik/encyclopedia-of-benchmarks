type I64Input = ptr UncheckedArray[int64]

proc car_pool*(input: I64Input, length: csize_t): int64
    {.cdecl, exportc: "car_pool".} =
  if input == nil or length < 2 or length > 194: return -1
  if input[0] < 0 or input[0] > 1000 or input[1] < 0 or input[1] > 64: return -1
  let capacity = input[0]
  let tripCount = int(input[1])
  if int(length) != 2 + 3 * tripCount: return -1

  var events: array[1001, int32]
  for trip in 0 ..< tripCount:
    let offset = 2 + 3 * trip
    let passengers = input[offset]
    let origin = input[offset + 1]
    let destination = input[offset + 2]
    if passengers < 1 or passengers > 1000 or origin < 0 or origin >= destination or destination > 1000:
      return -1
    events[int(origin)] += int32(passengers)
    events[int(destination)] -= int32(passengers)

  var occupants = 0'i32
  for position in 0 ..< 1000:
    occupants += events[position]
    if int64(occupants) > capacity: return 0
  1
