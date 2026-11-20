## Count primes through limit with Pritchard's dynamic wheel sieve.
const MaxLimit = 1024'i64
const LinkCount = 1026

proc sieve_of_pritchard*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "sieve_of_pritchard".} =
  if input.isNil or length < 1 or length > csize_t(2): return -1
  if length != 1 or input[0] < 2 or input[0] > MaxLimit: return -1

  let limit = int32(input[0])
  let sentinel = limit + 1
  var nextNode: array[LinkCount, int32]
  var previous: array[LinkCount, int32]
  nextNode[1] = sentinel
  nextNode[int(sentinel)] = sentinel
  previous[int(sentinel)] = 1
  var wheelLength = 2'i32
  var prime = 3'i32
  var primeCount = 1'i64

  while prime * prime <= limit:
    if wheelLength < limit:
      let product = prime * wheelLength
      let target = if product < limit: product else: limit
      var wheelValue = 1'i32
      var candidate = wheelLength + 1
      while candidate <= target:
        let tail = previous[int(sentinel)]
        nextNode[int(tail)] = candidate
        previous[int(candidate)] = tail
        nextNode[int(candidate)] = sentinel
        previous[int(sentinel)] = candidate
        wheelValue = nextNode[int(wheelValue)]
        candidate = wheelLength + wheelValue
      wheelLength = target

    var wheelValue = prime
    while prime * wheelValue <= wheelLength:
      wheelValue = nextNode[int(wheelValue)]
    while wheelValue > 1:
      wheelValue = previous[int(wheelValue)]
      let removed = prime * wheelValue
      let left = previous[int(removed)]
      let right = nextNode[int(removed)]
      nextNode[int(left)] = right
      previous[int(right)] = left
    inc primeCount
    prime = nextNode[1]

  if wheelLength < limit:
    var wheelValue = 1'i32
    var candidate = wheelLength + 1
    while candidate <= limit:
      let tail = previous[int(sentinel)]
      nextNode[int(tail)] = candidate
      previous[int(candidate)] = tail
      nextNode[int(candidate)] = sentinel
      previous[int(sentinel)] = candidate
      wheelValue = nextNode[int(wheelValue)]
      candidate = wheelLength + wheelValue
    wheelLength = limit

  var remaining = 0'i64
  var value = nextNode[1]
  while value != sentinel:
    inc remaining
    value = nextNode[int(value)]
  primeCount + remaining
