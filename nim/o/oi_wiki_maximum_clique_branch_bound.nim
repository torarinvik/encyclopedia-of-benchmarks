## Ordered candidate-intersection search with a suffix-optimum bound.
const MaxVertices = 24
const MaxParseableInput = 26

type CliqueSearch = object
  adjacency: array[MaxVertices, uint64]
  suffixBest: array[MaxVertices, int]
  best: int

proc bitCount(bitsInput: uint64): int =
  var bits = bitsInput
  while bits != 0:
    bits = bits and (bits - 1'u64)
    inc result

proc firstVertex(bitsInput: uint64): int =
  var bits = bitsInput
  while (bits and 1'u64) == 0:
    bits = bits shr 1
    inc result

proc searchClique(search: var CliqueSearch, candidateInput: uint64,
                  chosen: int): bool =
  if candidateInput == 0:
    if chosen > search.best:
      search.best = chosen
      return true
    return false
  var remaining = candidateInput
  while remaining != 0:
    if chosen + bitCount(remaining) <= search.best: return false
    let vertex = firstVertex(remaining)
    let bit = 1'u64 shl vertex
    remaining = remaining and not bit
    if chosen + search.suffixBest[vertex] <= search.best: return false
    if searchClique(search, remaining and search.adjacency[vertex], chosen + 1):
      return true
  false

proc oi_wiki_maximum_clique_branch_bound*(packed: ptr UncheckedArray[int64],
                                          length: csize_t): int64
    {.cdecl, exportc: "oi_wiki_maximum_clique_branch_bound".} =
  if packed.isNil or length < 1 or length > csize_t(MaxParseableInput): return -1
  let n64 = packed[0]
  if n64 < 0 or n64 > int64(MaxVertices) or int(length) != 1 + int(n64): return -1
  let n = int(n64)
  let domain = (1'u64 shl n) - 1'u64
  var search: CliqueSearch
  for vertex in 0 ..< n:
    let row = packed[1 + vertex]
    if row < 0 or (uint64(row) and not domain) != 0: return -1
    search.adjacency[vertex] = uint64(row)
    if (search.adjacency[vertex] and (1'u64 shl vertex)) != 0: return -1
  for left in 0 ..< n:
    for right in left + 1 ..< n:
      let forward = (search.adjacency[left] and (1'u64 shl right)) != 0
      let reverse = (search.adjacency[right] and (1'u64 shl left)) != 0
      if forward != reverse: return -1
  if n > 0:
    for root in countdown(n - 1, 0):
      let greater = domain and not ((1'u64 shl (root + 1)) - 1'u64)
      discard searchClique(search, search.adjacency[root] and greater, 1)
      search.suffixBest[root] = search.best
  int64(search.best)
