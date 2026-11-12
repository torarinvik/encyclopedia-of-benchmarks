const
  MaxN = 6
  MaxGenerators = 4
  MaxQueries = 8
  MaxInput = 76
  MaxStrongGenerators = 32
  MaxPending = 8192

type
  Code = uint32
  Layer = object
    generators: array[MaxStrongGenerators, Code]
    generatorCount: int
    inOrbit: array[MaxN, bool]
    orbit: array[MaxN, int]
    orbitCount: int
    transversal: array[MaxN, Code]
  Pending = object
    level: int
    value: Code

proc identity(n: int): Code =
  var result: Code = 0
  var place: Code = 1
  for point in 0 ..< n:
    result += Code(point + 1) * place
    place *= 7
  result

proc encode(images: array[MaxN, int], n: int): Code =
  var result: Code = 0
  var place: Code = 1
  for point in 0 ..< n:
    result += Code(images[point] + 1) * place
    place *= 7
  result

proc imageOf(valueInput: Code, point: int): int =
  var value = valueInput
  for _ in 0 ..< point: value = value div 7
  int(value mod 7) - 1

proc compose(first, second: Code, n: int): Code =
  var images: array[MaxN, int]
  for point in 0 ..< n: images[point] = imageOf(second, imageOf(first, point))
  encode(images, n)

proc inverse(value: Code, n: int): Code =
  var images: array[MaxN, int]
  for point in 0 ..< n: images[imageOf(value, point)] = point
  encode(images, n)

proc appendGenerator(layer: var Layer, value: Code): bool =
  for i in 0 ..< layer.generatorCount:
    if layer.generators[i] == value: return true
  if layer.generatorCount >= MaxStrongGenerators: return false
  layer.generators[layer.generatorCount] = value
  inc layer.generatorCount
  true

proc rebuildOrbit(layer: var Layer, base, n: int, id: Code) =
  for point in 0 ..< n: layer.inOrbit[point] = false
  layer.orbitCount = 1
  layer.orbit[0] = base
  layer.inOrbit[base] = true
  layer.transversal[base] = id
  var at = 0
  while at < layer.orbitCount:
    let point = layer.orbit[at]
    inc at
    let representative = layer.transversal[point]
    for g in 0 ..< layer.generatorCount:
      let image = imageOf(layer.generators[g], point)
      if not layer.inOrbit[image]:
        layer.inOrbit[image] = true
        layer.transversal[image] = compose(representative, layer.generators[g], n)
        layer.orbit[layer.orbitCount] = image
        inc layer.orbitCount

proc buildChain(layers: var array[MaxN, Layer], n: int,
                generators: array[MaxGenerators, Code], count: int): bool =
  let id = identity(n)
  var pending: array[MaxPending, Pending]
  var head = 0
  var tail = 0
  for i in 0 ..< count:
    pending[tail] = Pending(level: 0, value: generators[i])
    inc tail
  while head < tail:
    let item = pending[head]
    inc head
    var residue = item.value
    var level = item.level
    while level < n:
      let image = imageOf(residue, level)
      if not layers[level].inOrbit[image]: break
      residue = compose(residue, inverse(layers[level].transversal[image], n), n)
      inc level
    if residue == id or level == n: continue
    let inv = inverse(residue, n)
    if not appendGenerator(layers[level], residue) or not appendGenerator(layers[level], inv): return false
    rebuildOrbit(layers[level], level, n, id)
    if level + 1 < n:
      let orbitCount = layers[level].orbitCount
      let generatorCount = layers[level].generatorCount
      for orbitIndex in 0 ..< orbitCount:
        let point = layers[level].orbit[orbitIndex]
        let representative = layers[level].transversal[point]
        for g in 0 ..< generatorCount:
          let generator = layers[level].generators[g]
          let image = imageOf(generator, point)
          let schreier = compose(compose(representative, generator, n),
                                 inverse(layers[level].transversal[image], n), n)
          if schreier != id:
            if tail >= MaxPending: return false
            pending[tail] = Pending(level: level + 1, value: schreier)
            inc tail
  true

proc isMember(layers: array[MaxN, Layer], valueInput: Code, n: int): bool =
  let id = identity(n)
  var residue = valueInput
  for level in 0 ..< n:
    let image = imageOf(residue, level)
    if not layers[level].inOrbit[image]: return false
    residue = compose(residue, inverse(layers[level].transversal[image], n), n)
  residue == id

proc readPermutation(input: ptr UncheckedArray[int64], offset, n: int,
                      result: var Code): bool =
  var used: array[MaxN, bool]
  var images: array[MaxN, int]
  for point in 0 ..< n:
    let image = input[offset + point]
    if image < 0 or image >= n.int64 or used[image.int]: return false
    used[image.int] = true
    images[point] = image.int
  result = encode(images, n)
  true

proc storeLe(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc schreier_sims*(input: ptr UncheckedArray[int64], length: csize_t,
                    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "schreier_sims".} =
  if input.isNil or length < csize_t(3) or length > csize_t(MaxInput): return -1
  let nValue = input[0]
  let mValue = input[1]
  let qValue = input[2]
  if nValue < 1 or nValue > MaxN.int64 or mValue < 0 or mValue > MaxGenerators.int64 or
      qValue < 1 or qValue > MaxQueries.int64: return -1
  let n = nValue.int
  let m = mValue.int
  let q = qValue.int
  if length != csize_t(3 + n * (m + q)): return -1
  var generators: array[MaxGenerators, Code]
  var queries: array[MaxQueries, Code]
  var cursor = 3
  for i in 0 ..< m:
    if not readPermutation(input, cursor, n, generators[i]): return -1
    cursor += n
  for i in 0 ..< q:
    if not readPermutation(input, cursor, n, queries[i]): return -1
    cursor += n
  let required = 8 * (q + 1)
  if output.isNil or capacity < csize_t(required): return -2
  var layers: array[MaxN, Layer]
  let id = identity(n)
  for level in 0 ..< n:
    layers[level].inOrbit[level] = true
    layers[level].orbit[0] = level
    layers[level].orbitCount = 1
    layers[level].transversal[level] = id
  if not buildChain(layers, n, generators, m): return -1
  var order: int64 = 1
  for level in 0 ..< n: order *= layers[level].orbitCount.int64
  storeLe(output, 0, order)
  for i in 0 ..< q: storeLe(output, 8 * (i + 1), if isMember(layers, queries[i], n): 1'i64 else: 0'i64)
  int64(required)
