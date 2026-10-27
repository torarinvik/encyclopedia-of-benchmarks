const MaxStates = 4
const MaxActions = 3
const MaxInput = 29
const MaxOutput = 72

proc put64(output: ptr UncheckedArray[uint8], pos: int, value: int64) =
  let bits = cast[uint64](value)
  for j in 0 ..< 8: output[pos+j] = uint8((bits shr (8*j)) and 255)

proc mdp_value_iteration_deterministic*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc:"mdp_value_iteration_deterministic".} =
  if input.isNil or length < 7 or length > csize_t(MaxInput): return -1
  let s64=input[0]; let a64=input[1]; let h64=input[2]; let p=input[3]; let q=input[4]
  if s64<1 or s64>MaxStates or a64<1 or a64>MaxActions or h64<1 or h64>8 or q<1 or q>4 or p<0 or p>=q or int64(length)!=5+2*s64*a64: return -1
  let states=int(s64); let actions=int(a64); let horizon=int(h64)
  var rewards, targets: array[MaxStates, array[MaxActions, int64]]
  var at=5
  for s in 0..<states:
    for a in 0..<actions:
      let reward=input[at]; let target=input[at+1]; at+=2
      if reward < -100 or reward > 100 or target < 0 or target >= s64: return -1
      rewards[s][a]=reward; targets[s][a]=target
  var scale:int64=1
  for _ in 0..<horizon: scale*=q
  var value, nextValue, policy: array[MaxStates, int64]
  for _ in 0..<horizon:
    for s in 0..<states:
      var best=low(int64); var bestAction=0'i64
      for a in 0..<actions:
        let candidate=rewards[s][a]*scale+p*(value[int(targets[s][a])] div q)
        if candidate>best: best=candidate; bestAction=int64(a)
      nextValue[s]=best; policy[s]=bestAction
    for s in 0..<states: value[s]=nextValue[s]
  let bytes=8*(1+2*states)
  if output.isNil or capacity<csize_t(bytes): return -2
  var staged: array[MaxOutput, uint8]
  put64(addr staged[0],0,scale)
  for s in 0..<states: put64(addr staged[0],8*(1+s),value[s])
  for s in 0..<states: put64(addr staged[0],8*(1+states+s),policy[s])
  for b in 0..<bytes: output[b]=staged[b]
  int64(bytes)
