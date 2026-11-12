const
  MaxN = 64'i64
  EncodingBase = 65'i64

proc nextNode(input: ptr UncheckedArray[int64], node: int64): int64 =
  input[2 + int(node)]

proc functional_graph_cycle_parameters*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "functional_graph_cycle_parameters".} =
  if input.isNil or length < csize_t(3) or length > csize_t(MaxN + 2): return -1
  let n = input[0]
  let start = input[1]
  if n < 1 or n > MaxN or start < 0 or start >= n or length != csize_t(n + 2): return -1
  for i in 0 ..< int(n):
    let successor = input[2 + i]
    if successor < 0 or successor >= n: return -1

  var tortoise = nextNode(input, start)
  var hare = nextNode(input, nextNode(input, start))
  while tortoise != hare:
    tortoise = nextNode(input, tortoise)
    hare = nextNode(input, nextNode(input, hare))

  var mu = 0'i64
  tortoise = start
  while tortoise != hare:
    tortoise = nextNode(input, tortoise)
    hare = nextNode(input, hare)
    inc mu

  var lambda = 1'i64
  hare = nextNode(input, tortoise)
  while hare != tortoise:
    hare = nextNode(input, hare)
    inc lambda
  EncodingBase * mu + lambda
