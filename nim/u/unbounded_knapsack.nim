const MaxItems = 16
const MaxCapacity = 100

proc solve(item, capacity: int, values, weights: ptr UncheckedArray[int64], memo: var array[MaxItems, array[MaxCapacity+1, int64]]): int64 =
  if item == 0: return int64(capacity) div weights[0] * values[0]
  if memo[item][capacity] >= 0: return memo[item][capacity]
  let skip=solve(item-1,capacity,values,weights,memo)
  var take:int64=0
  if int64(capacity) >= weights[item]: take=values[item]+solve(item,capacity-int(weights[item]),values,weights,memo)
  memo[item][capacity]=max(take,skip)
  memo[item][capacity]

## Solve unbounded knapsack with the source's take-again or skip-previous recurrence.
proc unbounded_knapsack*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "unbounded_knapsack".} =
  if input == nil or length < 2: return -1
  if input[0]<0 or input[0]>MaxItems or input[1]<0 or input[1]>MaxCapacity:return -1
  let n=int(input[0]);let capacity=int(input[1])
  if length != csize_t(2+2*n):return -1
  if n==0:return 0
  let values=cast[ptr UncheckedArray[int64]](addr input[2])
  let weights=cast[ptr UncheckedArray[int64]](addr input[2+n])
  for i in 0..<n:
    if values[i]<1 or values[i]>100 or weights[i]<1 or weights[i]>100:return -1
  var memo:array[MaxItems,array[MaxCapacity+1,int64]]
  for i in 0..<MaxItems:
    for c in 0..MaxCapacity:memo[i][c] = -1
  solve(n-1,capacity,values,weights,memo)
