proc two_pointer*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "two_pointer".} =
  if length < 2 or length > 258: return -2
  let n=input[0]; let target=input[1]
  if n < 0 or n > 256 or length != csize_t(n + 2) or target < int64(low(int32)) or target > int64(high(int32)): return -2
  for i in 0 ..< int(n):
    if input[i + 2] < int64(low(int32)) or input[i + 2] > int64(high(int32)): return -2
    if i > 0 and input[i + 1] > input[i + 2]: return -2
  var left=0; var right=int(n)-1
  while left < right:
    let sum=input[left+2]+input[right+2]
    if sum == target: return int64(left*256+right)
    if sum < target: inc left else: dec right
  -1
