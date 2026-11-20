const MaxFaces = 32
const MaxParseableLength = 290
const Scale = 1_000_000'i64
type Point = tuple[x, y, z: int64]

proc coordinate(xyz: array[MaxFaces * 9, int64], face, corner, axis: int): int64 =
  xyz[9 * face + 3 * corner + axis]

proc edgeMatches(xyz: array[MaxFaces * 9, int64], face, edge, otherFace, otherEdge: int,
                 reverse: bool): bool =
  let edgeEnd = (edge + 1) mod 3
  let otherEnd = (otherEdge + 1) mod 3
  let otherStart = if reverse: otherEnd else: otherEdge
  let otherFinish = if reverse: otherEdge else: otherEnd
  for axis in 0 ..< 3:
    if coordinate(xyz, face, edge, axis) != coordinate(xyz, otherFace, otherStart, axis): return false
    if coordinate(xyz, face, edgeEnd, axis) != coordinate(xyz, otherFace, otherFinish, axis): return false
  true

proc cross(a, b: Point): Point =
  (a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x)

proc polyhedron_volume*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "polyhedron_volume".} =
  if input == nil or length < 1 or length > csize_t(MaxParseableLength): return -1
  let faceCountValue = input[0]
  if faceCountValue < 4 or faceCountValue > MaxFaces: return -1
  let faceCount = int(faceCountValue)
  if length != csize_t(1 + 9 * faceCount): return -1

  var xyz: array[MaxFaces * 9, int64]
  for face in 0 ..< faceCount:
    for corner in 0 ..< 3:
      for axis in 0 ..< 3:
        let value = input[1 + 9 * face + 3 * corner + axis]
        if value < -50 or value > 50: return -1
        xyz[9 * face + 3 * corner + axis] = value
    let a: Point = (coordinate(xyz, face, 0, 0), coordinate(xyz, face, 0, 1), coordinate(xyz, face, 0, 2))
    let b: Point = (coordinate(xyz, face, 1, 0), coordinate(xyz, face, 1, 1), coordinate(xyz, face, 1, 2))
    let c: Point = (coordinate(xyz, face, 2, 0), coordinate(xyz, face, 2, 1), coordinate(xyz, face, 2, 2))
    let ab: Point = (b.x - a.x, b.y - a.y, b.z - a.z)
    let ac: Point = (c.x - a.x, c.y - a.y, c.z - a.z)
    let normal = cross(ab, ac)
    if normal.x == 0 and normal.y == 0 and normal.z == 0: return -1

  for face in 0 ..< faceCount:
    for edge in 0 ..< 3:
      var sameCount = 0
      var reverseCount = 0
      for otherFace in 0 ..< faceCount:
        for otherEdge in 0 ..< 3:
          if edgeMatches(xyz, face, edge, otherFace, otherEdge, false): inc sameCount
          if edgeMatches(xyz, face, edge, otherFace, otherEdge, true): inc reverseCount
      if sameCount != 1 or reverseCount != 1: return -1

  var determinantSum = 0'i64
  for face in 0 ..< faceCount:
    let a: Point = (coordinate(xyz, face, 0, 0), coordinate(xyz, face, 0, 1), coordinate(xyz, face, 0, 2))
    let b: Point = (coordinate(xyz, face, 1, 0), coordinate(xyz, face, 1, 1), coordinate(xyz, face, 1, 2))
    let c: Point = (coordinate(xyz, face, 2, 0), coordinate(xyz, face, 2, 1), coordinate(xyz, face, 2, 2))
    let bc = cross(b, c)
    determinantSum += a.x * bc.x + a.y * bc.y + a.z * bc.z
  let sign = if determinantSum < 0: -1'i64 else: 1'i64
  let magnitude = uint64(abs(determinantSum))
  let scaled = magnitude * uint64(Scale)
  var quotient = scaled div 6'u64
  if 2'u64 * (scaled mod 6'u64) >= 6'u64: inc quotient
  let result = sign * int64(quotient)
  if output == nil or capacity < 8: return -2
  let bits = cast[uint64](result)
  for byte in 0 ..< 8:
    output[byte] = uint8((bits shr (byte * 8)) and 255'u64)
  8
