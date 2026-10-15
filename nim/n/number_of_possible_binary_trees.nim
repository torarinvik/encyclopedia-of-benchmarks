## Count labeled binary trees using the pinned Catalan-times-factorial formula.
proc number_of_possible_binary_trees*(nodeCount: int64): int64
    {.cdecl, exportc: "number_of_possible_binary_trees".} =
  if nodeCount < 1 or nodeCount > 14: return -1
  var binomial: int64 = 1
  for index in 0 ..< nodeCount:
    binomial *= 2 * nodeCount - index
    binomial = binomial div (index + 1)
  let catalan = binomial div (nodeCount + 1)
  var factorial: int64 = 1
  for factor in 2 .. nodeCount: factorial *= factor
  catalan * factorial
