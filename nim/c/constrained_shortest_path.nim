const Inf = high(int64)
const MaxNodes = 16
const MaxEdges = 64
const MaxResource = 32

proc constrained_shortest_path*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "constrained_shortest_path".} =
  if input.isNil or length < 5: return -2
  let nRaw = input[0]
  let mRaw = input[1]
  let startRaw = input[2]
  let targetRaw = input[3]
  let limitRaw = input[4]
  if nRaw < 1 or nRaw > MaxNodes or mRaw < 0 or mRaw > MaxEdges or limitRaw < 0 or limitRaw > MaxResource: return -2
  let n = int(nRaw)
  let m = int(mRaw)
  let limit = int(limitRaw)
  if length != csize_t(5+4*m) or startRaw < 0 or startRaw >= nRaw or targetRaw < 0 or targetRaw >= nRaw: return -2
  for e in 0..<m:
    let p = 5+4*e
    if input[p] < 0 or input[p] >= nRaw or input[p+1] < 0 or input[p+1] >= nRaw or input[p+2] < 0 or input[p+2] > 1000 or input[p+3] < 1 or input[p+3] > MaxResource: return -2
  var dp: array[33, array[16, int64]]
  for r in 0..limit:
    for u in 0..<n: dp[r][u] = Inf
  dp[0][int(startRaw)] = 0
  for r in 0..limit:
    for u in 0..<n:
      if dp[r][u] == Inf: continue
      for e in 0..<m:
        let p = 5+4*e
        if input[p] != int64(u): continue
        let resource = int(input[p+3])
        if r+resource <= limit:
          let v = int(input[p+1])
          let candidate = dp[r][u] + input[p+2]
          if candidate < dp[r+resource][v]: dp[r+resource][v] = candidate
  var answer = Inf
  for r in 0..limit:
    if dp[r][int(targetRaw)] < answer: answer = dp[r][int(targetRaw)]
  if answer == Inf: -1 else: answer
