import std/math

const MaxSamples = 4
const Cells = 27
const Width = 2.5'f32
const Oversample = 0.608933'f32
const Coeff: array[15, float32] = [
  0.210580722890567e-22'f32, 0.380715242345326e-19'f32, 0.479440257548300e-16'f32,
  0.435125971262668e-13'f32, 0.300931127112960e-10'f32, 0.160224679395361e-7'f32,
  0.654858370096785e-5'f32, 0.202591084143397e-2'f32, 0.463076284721000e0'f32,
  0.754337328948189e2'f32, 0.830792541809429e4'f32, 0.571661130563785e6'f32,
  0.216415572361227e8'f32, 0.356644482244025e9'f32, 0.144048298227235e10'f32
]

proc decode(raw: int64): float32 = float32(raw) / 1_000_000'f32

proc kernel(value: float32): float32 =
  let z = value * value
  var num = Coeff[0]
  for i in 1 ..< 15:
    let product = z * num
    num = product + Coeff[i]
  var den = z - 0.307646912682801e4'f32
  den = z * den
  den = den + 0.347626332405882e7'f32
  den = z * den
  den = den - 0.144048298227235e10'f32
  -num / den

proc betaValue(): float32 =
  var first = 4.0'f32 * Width
  first = first * Width
  let divisor = Oversample * Oversample
  first = first / divisor
  let shifted = float64(Oversample) - 0.5
  var argument = float64(first) * shifted
  argument = argument * shifted
  argument = argument - 0.8
  float32(3.14159265359 * sqrt(argument))

proc weight(v, inverse, beta, sdc: float32): float32 =
  let product = v * inverse
  let radicand = 1.0 - float64(product)
  let argument = float32(float64(beta) * sqrt(radicand))
  kernel(argument) * sdc

proc lower(k, cutoff: float32): int =
  let difference = k - cutoff
  if difference < 0'f32: 0 else: int(difference)

proc upper(k, cutoff: float32): int =
  let total = k + cutoff
  if total > 2'f32: 2 else: int(total)

proc quantize(value: float32): int64 =
  let scaled = value * 1000'f32
  let magnitude = if scaled < 0'f32: -scaled else: scaled
  var whole = int64(magnitude)
  if magnitude - float32(whole) >= 0.5'f32: inc whole
  if scaled < 0'f32: -whole else: whole

proc parboil_mri_gridding(input: ptr UncheckedArray[int64], inputLength: int): int64 {.exportc.} =
  if input.isNil or inputLength < 1 or inputLength > 25: return -1
  let n = input[0]
  if n < 0 or n > int64(MaxSamples) or inputLength != 1 + 6 * int(n): return -1
  for s in 0 ..< int(n):
    let p = 1 + 6*s
    for axis in 0 ..< 3:
      if input[p+axis] notin [0'i64, 1_000_000'i64, 2_000_000'i64]: return -1
    if input[p+3] < -1_000_000 or input[p+3] > 1_000_000 or
       input[p+4] < -1_000_000 or input[p+4] > 1_000_000 or
       input[p+5] < 0 or input[p+5] > 1_000_000: return -1

  var realGrid, imagGrid, density: array[Cells, float32]
  let cutoff = float32(float64(Width) / 2.0)
  let cutoff2 = cutoff * cutoff
  let inverse = 1'f32 / cutoff2
  let beta = betaValue()
  for s in 0 ..< int(n):
    let p = 1 + 6*s
    let kx=decode(input[p]); let ky=decode(input[p+1]); let kz=decode(input[p+2])
    let sr=decode(input[p+3]); let si=decode(input[p+4]); let sdc=decode(input[p+5])
    if (sr != 0'f32 or si != 0'f32) and sdc != 0'f32:
      let x0=lower(kx,cutoff); let x1=upper(kx,cutoff)
      let y0=lower(ky,cutoff); let y1=upper(ky,cutoff)
      let z0=lower(kz,cutoff); let z1=upper(kz,cutoff)
      for z in z0 .. z1:
        let dz=kz-float32(z); let dz2=dz*dz
        if dz2 < cutoff2:
          for y in y0 .. y1:
            let dy=ky-float32(y); let dy2=dy*dy; let yz=dz2+dy2
            if yz < cutoff2:
              for x in x0 .. x1:
                let dx=kx-float32(x); let dx2=dx*dx; let v=yz+dx2
                if v < cutoff2:
                  let index=x+3*y+9*z
                  let w=weight(v,inverse,beta,sdc)
                  let dr=w*sr; let di=w*si
                  realGrid[index]=realGrid[index]+dr
                  imagGrid[index]=imagGrid[index]+di
                  density[index]=float32(float64(density[index])+1.0)
  var checksum: int64 = 0
  for i in 0 ..< Cells:
    checksum += int64(i+1)*(quantize(realGrid[i])+quantize(imagGrid[i])+int64(density[i]))
  checksum
