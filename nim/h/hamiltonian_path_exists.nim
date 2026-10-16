const MaxVertices = 8
const MaxStates = 256
const MaxInputLength = 65
proc hamiltonian_path_exists*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "hamiltonian_path_exists".} =
  if input == nil or length < 1 or length > csize_t(MaxInputLength): return -1
  if input[0] < 0 or input[0] > MaxVertices: return -1
  let n = int(input[0])
  if int(length) != 1 + n*n: return -1
  var routes: array[MaxVertices, int]
  for row in 0 ..< n:
    for col in 0 ..< n:
      let cell=input[1+row*n+col]
      if cell != 0 and cell != 1: return -1
      if cell == 1: routes[row] = routes[row] or (1 shl col)
  var dp: array[MaxStates*MaxVertices, bool]
  for start in 0 ..< n: dp[(1 shl start)*MaxVertices+start]=true
  let full=(1 shl n)-1
  for subset in 1 ..< (1 shl n):
    for last in 0 ..< n:
      if not dp[subset*MaxVertices+last]: continue
      for next in 0 ..< n:
        let bit=1 shl next
        if (subset and bit)==0 and (routes[last] and bit)!=0: dp[(subset or bit)*MaxVertices+next]=true
  for last in 0 ..< n:
    if dp[full*MaxVertices+last]: return 1
  0
