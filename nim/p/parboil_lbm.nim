const
  Q = 19
  CellCount = 27
  HaloCellCount = 125
  Dx: array[Q, int] = [0,0,0,1,-1,0,0,1,-1,1,-1,0,0,0,0,1,1,-1,-1]
  Dy: array[Q, int] = [0,1,-1,0,0,0,0,1,1,-1,-1,1,1,-1,-1,0,0,0,0]
  Dz: array[Q, int] = [0,0,0,0,0,1,-1,0,0,0,0,1,-1,1,-1,1,-1,1,-1]
  Opp: array[Q, int] = [0,2,1,4,3,6,5,10,9,8,7,14,13,12,11,18,17,16,15]

proc cellIndex(x, y, z: int): int = x + 3*y + 9*z
proc haloIndex(x, y, z, q: int): int = (((z+1)*5+(y+1))*5+(x+1))*Q+q

proc initialWeight(q: int): float32 =
  if q == 0: return float32(1.0 / 3.0)
  if q <= 6: return float32(1.0 / 18.0)
  float32(1.0 / 36.0)

proc axisFactor(u: float32, positive: bool, u2: float32): float32 =
  var product = 4.5'f32 * u
  if positive: product = product + 3.0'f32
  else: product = product - 3.0'f32
  product = u * product
  product = 1.0'f32 + product
  product - u2

proc diagonalFactor(cu, u2: float32): float32 =
  var product = 4.5'f32 * cu
  product = product + 3.0'f32
  product = cu * product
  product = 1.0'f32 + product
  product - u2

proc collide(source, rho, factor: float32, weight: float64): float32 =
  let omega = 1.95'f32
  let base = (1.0'f32 - omega) * source
  var equilibrium = weight * float64(omega)
  equilibrium = equilibrium * float64(rho)
  equilibrium = equilibrium * float64(factor)
  float32(float64(base) + equilibrium)

proc collideCell(f, post: ptr UncheckedArray[float32]) =
  var rho = f[0]
  for q in 1 ..< Q: rho = rho + f[q]
  var ux = f[3]
  ux = ux-f[4]; ux = ux+f[7]; ux = ux-f[8]; ux = ux+f[9]; ux = ux-f[10]
  ux = ux+f[15]; ux = ux+f[16]; ux = ux-f[17]; ux = ux-f[18]
  var uy = f[1]
  uy = uy-f[2]; uy = uy+f[7]; uy = uy+f[8]; uy = uy-f[9]; uy = uy-f[10]
  uy = uy+f[11]; uy = uy+f[12]; uy = uy-f[13]; uy = uy-f[14]
  var uz = f[5]
  uz = uz-f[6]; uz = uz+f[11]; uz = uz-f[12]; uz = uz+f[13]; uz = uz-f[14]
  uz = uz+f[15]; uz = uz-f[16]; uz = uz+f[17]; uz = uz-f[18]
  ux = ux/rho; uy = uy/rho; uz = uz/rho
  var u2 = ux*ux
  u2 = u2 + uy*uy
  u2 = u2 + uz*uz
  u2 = 1.5'f32 * u2
  post[0] = collide(f[0], rho, 1.0'f32-u2, 1.0/3.0)
  post[1] = collide(f[1], rho, axisFactor(uy, true, u2), 1.0/18.0)
  post[2] = collide(f[2], rho, axisFactor(uy, false, u2), 1.0/18.0)
  post[3] = collide(f[3], rho, axisFactor(ux, true, u2), 1.0/18.0)
  post[4] = collide(f[4], rho, axisFactor(ux, false, u2), 1.0/18.0)
  post[5] = collide(f[5], rho, axisFactor(uz, true, u2), 1.0/18.0)
  post[6] = collide(f[6], rho, axisFactor(uz, false, u2), 1.0/18.0)
  var cu = ux+uy; post[7] = collide(f[7], rho, diagonalFactor(cu,u2), 1.0/36.0)
  cu = -ux+uy; post[8] = collide(f[8], rho, diagonalFactor(cu,u2), 1.0/36.0)
  cu = ux-uy; post[9] = collide(f[9], rho, diagonalFactor(cu,u2), 1.0/36.0)
  cu = -ux-uy; post[10] = collide(f[10], rho, diagonalFactor(cu,u2), 1.0/36.0)
  cu = uy+uz; post[11] = collide(f[11], rho, diagonalFactor(cu,u2), 1.0/36.0)
  cu = uy-uz; post[12] = collide(f[12], rho, diagonalFactor(cu,u2), 1.0/36.0)
  cu = -uy+uz; post[13] = collide(f[13], rho, diagonalFactor(cu,u2), 1.0/36.0)
  cu = -uy-uz; post[14] = collide(f[14], rho, diagonalFactor(cu,u2), 1.0/36.0)
  cu = ux+uz; post[15] = collide(f[15], rho, diagonalFactor(cu,u2), 1.0/36.0)
  cu = ux-uz; post[16] = collide(f[16], rho, diagonalFactor(cu,u2), 1.0/36.0)
  cu = -ux+uz; post[17] = collide(f[17], rho, diagonalFactor(cu,u2), 1.0/36.0)
  cu = -ux-uz; post[18] = collide(f[18], rho, diagonalFactor(cu,u2), 1.0/36.0)

proc quantize(value: float32): int64 =
  let scaled = value * 1_000_000'f32
  let magnitude = abs(scaled)
  var whole = int64(magnitude)
  if magnitude - float32(whole) >= 0.5'f32: inc whole
  if scaled < 0'f32: -whole else: whole

## Clean-room Parboil D3Q19 profile; Illinois Open Source License is in package docs.
proc parboil_lbm*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "parboil_lbm".} =
  if input == nil or length != csize_t(Q): return -1
  var nonzero = false
  for q in 0 ..< Q:
    if input[q] < 0 or input[q] > 100_000: return -1
    if input[q] != 0: nonzero = true
  if not nonzero: return -1

  var source: array[CellCount * Q, float32]
  var destination: array[HaloCellCount * Q, float32]
  for z in 0 ..< 3:
    for y in 0 ..< 3:
      for x in 0 ..< 3:
        let cell = cellIndex(x,y,z)
        for q in 0 ..< Q:
          let weight = initialWeight(q)
          source[cell*Q+q] = weight
          destination[haloIndex(x,y,z,q)] = weight
  for q in 0 ..< Q:
    source[cellIndex(1,1,1)*Q+q] = float32(input[q]) / 1_000_000'f32

  for z in 0 ..< 3:
    for y in 0 ..< 3:
      for x in 0 ..< 3:
        let cell = cellIndex(x,y,z)
        let obstacle = x == 0 or x == 2 or y == 0 or y == 2 or z == 0 or z == 2
        var post: array[Q, float32]
        if not obstacle: collideCell(unsafeAddr source[cell*Q], addr post[0])
        for q in 0 ..< Q:
          let outgoing = if obstacle: source[cell*Q+Opp[q]] else: post[q]
          destination[haloIndex(x+Dx[q],y+Dy[q],z+Dz[q],q)] = outgoing

  var checksum = 0'i64
  for z in 0 ..< 3:
    for y in 0 ..< 3:
      for x in 0 ..< 3:
        let cell = cellIndex(x,y,z)
        for q in 0 ..< Q:
          checksum += int64(cell+1) * quantize(destination[haloIndex(x,y,z,q)])
  checksum
