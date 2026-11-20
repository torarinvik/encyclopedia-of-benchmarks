const
  MaxVertices = 7
  MaxShapes = 48
  MaxWidth = 14
  MaxCandidates = 37
  MaxOutput = 674

type
  Shape = array[MaxWidth, uint8]
  Candidate = object
    size: int
    text: Shape
  Generator = object
    shapes: array[MaxVertices + 1, array[MaxShapes, Shape]]
    counts: array[MaxVertices + 1, int]
    target: int

proc shapeLess(left, right: Shape, width: int): bool =
  for index in 0 ..< width:
    if left[index] < right[index]: return true
    if left[index] > right[index]: return false
  false

proc candidateLess(left, right: Candidate): bool =
  shapeLess(left.text, right.text, MaxWidth)

proc enumerateMultisets(generator: var Generator, candidates: openArray[Candidate],
                        start, remaining: int, children: var Shape, childLength: int) =
  if remaining == 0:
    let shapeIndex = generator.counts[generator.target]
    var shape: Shape
    shape[0] = uint8(ord('('))
    for index in 0 ..< childLength:
      shape[index + 1] = children[index]
    shape[childLength + 1] = uint8(ord(')'))
    generator.shapes[generator.target][shapeIndex] = shape
    inc generator.counts[generator.target]
    return

  for index in start ..< candidates.len:
    let childSize = candidates[index].size
    if childSize > remaining: continue
    let encodedLength = 2 * childSize
    for byte in 0 ..< encodedLength:
      children[childLength + byte] = candidates[index].text[byte]
    enumerateMultisets(generator, candidates, index, remaining - childSize,
                       children, childLength + encodedLength)

proc build(generator: var Generator, maximum: int) =
  generator.counts[1] = 1
  generator.shapes[1][0][0] = uint8(ord('('))
  generator.shapes[1][0][1] = uint8(ord(')'))

  for target in 2 .. maximum:
    generator.target = target
    var candidates: array[MaxCandidates, Candidate]
    var candidateCount = 0
    for size in 1 ..< target:
      for shapeIndex in 0 ..< generator.counts[size]:
        candidates[candidateCount].size = size
        candidates[candidateCount].text = generator.shapes[size][shapeIndex]
        inc candidateCount

    for index in 1 ..< candidateCount:
      let saved = candidates[index]
      var place = index
      while place > 0 and candidateLess(saved, candidates[place - 1]):
        candidates[place] = candidates[place - 1]
        dec place
      candidates[place] = saved

    var children: Shape
    enumerateMultisets(generator, candidates.toOpenArray(0, candidateCount - 1),
                       0, target - 1, children, 0)

    let width = 2 * target
    for index in 1 ..< generator.counts[target]:
      let saved = generator.shapes[target][index]
      var place = index
      while place > 0 and shapeLess(saved, generator.shapes[target][place - 1], width):
        generator.shapes[target][place] = generator.shapes[target][place - 1]
        dec place
      generator.shapes[target][place] = saved

proc list_rooted_trees*(input: ptr UncheckedArray[int64], length: csize_t,
                        output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "list_rooted_trees".} =
  if input.isNil or length != 1: return -1
  if input[0] < 1 or input[0] > MaxVertices: return -1
  let vertices = int(input[0])

  var generator: Generator
  generator.build(vertices)
  let count = generator.counts[vertices]
  let width = 2 * vertices
  let needed = 2 + count * width
  var staged: array[MaxOutput, uint8]
  staged[0] = uint8(count and 0xff)
  staged[1] = uint8((count shr 8) and 0xff)
  var position = 2
  for shapeIndex in 0 ..< count:
    for byte in 0 ..< width:
      staged[position] = generator.shapes[vertices][shapeIndex][byte]
      inc position

  if output.isNil or capacity < needed.csize_t: return -2
  for byte in 0 ..< needed:
    output[byte] = staged[byte]
  needed.int64
