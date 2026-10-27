const MaxInput = 4
const MaxTrips = 32

proc ski_rental_deterministic*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "ski_rental_deterministic".} =
  if input.isNil or length < csize_t(3) or length > csize_t(MaxInput): return -1
  let rent = input[0]
  let purchase = input[1]
  let trips = input[2]
  if int64(length) != 3 or rent < 1 or rent > 32 or purchase < 1 or purchase > 64 or trips < 0 or trips > int64(MaxTrips): return -1
  let count = int(trips)
  if output.isNil or capacity < csize_t(count): return -2
  var actions: array[MaxTrips, uint8]
  let threshold = purchase div rent
  for trip in 0..<count:
    if int64(trip) < threshold: actions[trip] = 0
    elif int64(trip) == threshold: actions[trip] = 1
    else: actions[trip] = 2
  for trip in 0..<count: output[trip] = actions[trip]
  int64(count)
