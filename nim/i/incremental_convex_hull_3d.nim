## Exact incremental 3D convex hull volume for general-position points.
const PointCapacity = 6
const FaceCapacity = 64
const EdgeCapacity = 3 * FaceCapacity

proc sideOfFace(points: openArray[int64], a, b, c, point: int): int64 =
  let abx = points[3*b] - points[3*a]
  let aby = points[3*b+1] - points[3*a+1]
  let abz = points[3*b+2] - points[3*a+2]
  let acx = points[3*c] - points[3*a]
  let acy = points[3*c+1] - points[3*a+1]
  let acz = points[3*c+2] - points[3*a+2]
  let apx = points[3*point] - points[3*a]
  let apy = points[3*point+1] - points[3*a+1]
  let apz = points[3*point+2] - points[3*a+2]
  (aby*acz-abz*acy)*apx + (abz*acx-abx*acz)*apy + (abx*acy-aby*acx)*apz

proc centerSide(points: openArray[int64], a, b, c: int,
                centerSum: array[3, int64]): int64 =
  let abx = points[3*b] - points[3*a]
  let aby = points[3*b+1] - points[3*a+1]
  let abz = points[3*b+2] - points[3*a+2]
  let acx = points[3*c] - points[3*a]
  let acy = points[3*c+1] - points[3*a+1]
  let acz = points[3*c+2] - points[3*a+2]
  let dx = centerSum[0] - 4*points[3*a]
  let dy = centerSum[1] - 4*points[3*a+1]
  let dz = centerSum[2] - 4*points[3*a+2]
  (aby*acz-abz*acy)*dx + (abz*acx-abx*acz)*dy + (abx*acy-aby*acx)*dz

proc originDeterminant(points: openArray[int64], a, b, c: int): int64 =
  let ax=points[3*a]; let ay=points[3*a+1]; let az=points[3*a+2]
  let bx=points[3*b]; let by=points[3*b+1]; let bz=points[3*b+2]
  let cx=points[3*c]; let cy=points[3*c+1]; let cz=points[3*c+2]
  ax*(by*cz-bz*cy) + ay*(bz*cx-bx*cz) + az*(bx*cy-by*cx)

proc incremental_convex_hull_3d*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "incremental_convex_hull_3d".} =
  if input.isNil or length < 1 or length > 20: return -1
  if input[0] < 4 or input[0] > PointCapacity: return -1
  let n = int(input[0])
  if length != csize_t(1 + 3*n): return -1
  var points: array[18, int64]
  for i in 0 ..< 3*n:
    if input[i+1] < -10 or input[i+1] > 10: return -1
    points[i] = input[i+1]
  for i in 0 ..< n:
    for j in i+1 ..< n:
      if points[3*i] == points[3*j] and points[3*i+1] == points[3*j+1]
          and points[3*i+2] == points[3*j+2]: return -1
  for i in 0 ..< n:
    for j in i+1 ..< n:
      for k in j+1 ..< n:
        for ell in k+1 ..< n:
          if sideOfFace(points, i, j, k, ell) == 0: return -1

  var centerSum: array[3, int64]
  for i in 0 ..< 4:
    for axis in 0 ..< 3: centerSum[axis] += points[3*i+axis]
  var faceA, faceB, faceC: array[FaceCapacity, int]
  faceA[0..3] = [0, 0, 0, 1]
  faceB[0..3] = [1, 3, 2, 3]
  faceC[0..3] = [2, 1, 3, 2]
  var faceCount = 4
  for f in 0 ..< faceCount:
    if centerSide(points, faceA[f], faceB[f], faceC[f], centerSum) > 0:
      swap(faceB[f], faceC[f])

  for point in 4 ..< n:
    var visible: array[FaceCapacity, bool]
    var visibleCount = 0
    for f in 0 ..< faceCount:
      visible[f] = sideOfFace(points, faceA[f], faceB[f], faceC[f], point) > 0
      if visible[f]: inc visibleCount
    if visibleCount == 0: continue
    var edgeA, edgeB: array[EdgeCapacity, int]
    var edgeCount = 0
    for f in 0 ..< faceCount:
      if visible[f]:
        edgeA[edgeCount] = faceA[f]; edgeB[edgeCount] = faceB[f]; inc edgeCount
        edgeA[edgeCount] = faceB[f]; edgeB[edgeCount] = faceC[f]; inc edgeCount
        edgeA[edgeCount] = faceC[f]; edgeB[edgeCount] = faceA[f]; inc edgeCount
    var nextA, nextB, nextC: array[FaceCapacity, int]
    var nextCount = 0
    for f in 0 ..< faceCount:
      if not visible[f]:
        nextA[nextCount] = faceA[f]; nextB[nextCount] = faceB[f]; nextC[nextCount] = faceC[f]
        inc nextCount
    for edge in 0 ..< edgeCount:
      var copies = 0
      for other in 0 ..< edgeCount:
        if (edgeA[edge] == edgeA[other] and edgeB[edge] == edgeB[other])
            or (edgeA[edge] == edgeB[other] and edgeB[edge] == edgeA[other]): inc copies
      if copies == 1:
        if nextCount >= FaceCapacity: return -1
        var a = edgeA[edge]; var b = edgeB[edge]; var c = point
        if centerSide(points, a, b, c, centerSum) > 0: swap(b, c)
        nextA[nextCount] = a; nextB[nextCount] = b; nextC[nextCount] = c; inc nextCount
    for f in 0 ..< nextCount:
      faceA[f] = nextA[f]; faceB[f] = nextB[f]; faceC[f] = nextC[f]
    faceCount = nextCount

  var volumeSix = 0'i64
  for f in 0 ..< faceCount:
    volumeSix += originDeterminant(points, faceA[f], faceB[f], faceC[f])
  volumeSix
