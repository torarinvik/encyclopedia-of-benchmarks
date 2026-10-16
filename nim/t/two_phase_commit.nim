const MaxParticipants = 64
const MaxInput = 68

proc two_phase_commit*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "two_phase_commit".} =
  if input.isNil or length < 5 or length > MaxInput: return -1
  let participantCount = input[0]
  let timeoutMs = input[1]
  let startTimeMs = input[2]
  let currentTimeMs = input[3]
  if participantCount < 1 or participantCount > MaxParticipants: return -1
  if length != csize_t(4 + participantCount): return -1
  if timeoutMs < 1: return -1
  if startTimeMs < 0 or currentTimeMs < startTimeMs: return -1

  var votesReceived = 0'i64
  var commitVotes = 0'i64
  var hasAbort = false
  for i in 0 ..< int(participantCount):
    let vote = input[4 + i]
    if vote < 0 or vote > 2: return -1
    if vote == 0:
      inc votesReceived
      inc commitVotes
    elif vote == 1:
      inc votesReceived
      hasAbort = true

  var state = 1'i64
  if votesReceived == participantCount:
    state = if hasAbort: 3 else: 2
  let timedOut = if currentTimeMs - startTimeMs > timeoutMs: 1'i64 else: 0'i64
  (((state * 65 + votesReceived) * 65 + commitVotes) * 2 + timedOut)
