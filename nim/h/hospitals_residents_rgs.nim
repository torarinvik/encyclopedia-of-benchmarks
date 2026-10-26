const MaxR = 8
const MaxH = 8
const MaxInput = 154
const MaxOutput = 64

proc put64(output: ptr UncheckedArray[uint8], position: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[position + byte] = uint8((bits shr (8 * byte)) and 255)

proc hospitals_residents_rgs*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "hospitals_residents_rgs".} =
  if input.isNil or length < csize_t(5) or length > csize_t(MaxInput): return -1
  let r64 = input[0]
  let h64 = input[1]
  if r64 < 1 or r64 > int64(MaxR) or h64 < 1 or h64 > int64(MaxH): return -1
  let r = int(r64)
  let h = int(h64)
  let expected = 2 + 2*h + r + 2*r*h
  if int64(length) != int64(expected): return -1
  let capOffset = 2
  let rlenOffset = capOffset + h
  let rprefOffset = rlenOffset + r
  let hlenOffset = rprefOffset + r*h
  let hprefOffset = hlenOffset + h
  var capacities: array[MaxH, int64]
  var residentLength: array[MaxR, int64]
  var residentPref: array[MaxR * MaxH, int64]
  var hospitalLength: array[MaxH, int64]
  var hospitalRank: array[MaxH * MaxR, int64]
  var assignment: array[MaxR, int64]
  var nextChoice: array[MaxR, int]
  var occupancy: array[MaxH, int]
  for hospital in 0 ..< h:
    capacities[hospital] = input[capOffset + hospital]
    hospitalLength[hospital] = input[hlenOffset + hospital]
    if capacities[hospital] < 1 or capacities[hospital] > r64 or
        hospitalLength[hospital] < 0 or hospitalLength[hospital] > r64: return -1
    for resident in 0 ..< r: hospitalRank[hospital*MaxR + resident] = -1
  for resident in 0 ..< r:
    residentLength[resident] = input[rlenOffset + resident]
    if residentLength[resident] < 0 or residentLength[resident] > h64: return -1
    var seen: array[MaxH, bool]
    for slot in 0 ..< h:
      let value = input[rprefOffset + resident*h + slot]
      if slot < int(residentLength[resident]):
        if value < 0 or value >= h64 or seen[int(value)]: return -1
        seen[int(value)] = true
        residentPref[resident*MaxH + slot] = value
      else:
        if value != -1: return -1
        residentPref[resident*MaxH + slot] = -1
    assignment[resident] = -1
  for hospital in 0 ..< h:
    var seen: array[MaxR, bool]
    for slot in 0 ..< r:
      let value = input[hprefOffset + hospital*r + slot]
      if slot < int(hospitalLength[hospital]):
        if value < 0 or value >= r64 or seen[int(value)]: return -1
        seen[int(value)] = true
        hospitalRank[hospital*MaxR + int(value)] = int64(slot)
      else:
        if value != -1: return -1
  for resident in 0 ..< r:
    for hospital in 0 ..< h:
      var accepts = false
      for slot in 0 ..< int(residentLength[resident]):
        if residentPref[resident*MaxR + slot] == int64(hospital): accepts = true
      if accepts != (hospitalRank[hospital*MaxR + resident] >= 0): return -1

  let outputBytes = 8*r
  if output.isNil or capacity < csize_t(outputBytes): return -2
  while true:
    var proposer = r
    for resident in 0 ..< r:
      if assignment[resident] == -1 and nextChoice[resident] < int(residentLength[resident]):
        proposer = resident
        break
    if proposer == r: break
    let hospital = int(residentPref[proposer*MaxR + nextChoice[proposer]])
    inc nextChoice[proposer]
    if occupancy[hospital] < int(capacities[hospital]):
      assignment[proposer] = int64(hospital)
      inc occupancy[hospital]
    else:
      var worst = r
      for resident in 0 ..< r:
        if assignment[resident] == int64(hospital) and
            (worst == r or hospitalRank[hospital*MaxR + resident] > hospitalRank[hospital*MaxR + worst]):
          worst = resident
      if worst == r: return -1
      if hospitalRank[hospital*MaxR + proposer] < hospitalRank[hospital*MaxR + worst]:
        assignment[worst] = -1
        assignment[proposer] = int64(hospital)
  var staged: array[MaxOutput, uint8]
  for resident in 0 ..< r: put64(addr staged[0], 8*resident, assignment[resident])
  for byte in 0 ..< outputBytes: output[byte] = staged[byte]
  int64(outputBytes)
