## Fixed-table improved Perlin gradient noise for one bounded 3D point.
import math

const Permutation: array[256, int32] = [
  151'i32,160,137,91,90,15,131,13,201,95,96,53,194,233,7,225,
  140,36,103,30,69,142,8,99,37,240,21,10,23,190,6,148,
  247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,
  57,177,33,88,237,149,56,87,174,20,125,136,171,168,68,175,
  74,165,71,134,139,48,27,166,77,146,158,231,83,111,229,122,
  60,211,133,230,220,105,92,41,55,46,245,40,244,102,143,54,
  65,25,63,161,1,216,80,73,209,76,132,187,208,89,18,169,
  200,196,135,130,116,188,159,86,164,100,109,198,173,186,3,64,
  52,217,226,250,124,123,5,202,38,147,118,126,255,82,85,212,
  207,206,59,227,47,16,58,17,182,189,28,42,223,183,170,213,
  119,248,152,2,44,154,163,70,221,153,101,155,167,43,172,9,
  129,22,39,253,19,98,108,110,79,113,224,232,178,185,112,104,
  218,246,97,228,251,34,242,193,238,210,144,12,191,179,162,241,
  81,51,145,235,249,14,239,107,49,192,214,31,181,199,106,157,
  184,84,204,176,115,121,50,45,127,4,150,254,138,236,205,93,
  222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180]

proc pnLookup(index: int32): int32 = Permutation[int(index and 255'i32)]
proc pnFade(t: float64): float64 = t*t*t*(t*(t*6.0-15.0)+10.0)
proc pnMix(t, a, b: float64): float64 = a+t*(b-a)
proc pnGradient(hash: int32, x, y, z: float64): float64 =
  let k = hash and 15
  let u = if k < 8: x else: y
  let v = if k < 4: y elif k == 12 or k == 14: x else: z
  (if (k and 1) == 0: u else: -u) + (if (k and 2) == 0: v else: -v)

proc improved_perlin_noise_3d*(xInput, yInput, zInput: float64): float64
    {.cdecl, exportc: "improved_perlin_noise_3d".} =
  if xInput != xInput or yInput != yInput or zInput != zInput: return -1.0
  if xInput < -1_000_000.0 or xInput > 1_000_000.0 or
     yInput < -1_000_000.0 or yInput > 1_000_000.0 or
     zInput < -1_000_000.0 or zInput > 1_000_000.0: return -1.0
  let fx = floor(xInput); let fy = floor(yInput); let fz = floor(zInput)
  let ix = int32(int64(fx) and 255); let iy = int32(int64(fy) and 255); let iz = int32(int64(fz) and 255)
  let x = xInput-fx; let y = yInput-fy; let z = zInput-fz
  let u = pnFade(x); let v = pnFade(y); let w = pnFade(z)
  let a = pnLookup(ix)+iy; let aa = pnLookup(a)+iz; let ab = pnLookup(a+1)+iz
  let b = pnLookup(ix+1)+iy; let ba = pnLookup(b)+iz; let bb = pnLookup(b+1)+iz
  pnMix(w,
    pnMix(v, pnMix(u,pnGradient(pnLookup(aa),x,y,z),pnGradient(pnLookup(ba),x-1.0,y,z)),
              pnMix(u,pnGradient(pnLookup(ab),x,y-1.0,z),pnGradient(pnLookup(bb),x-1.0,y-1.0,z))),
    pnMix(v, pnMix(u,pnGradient(pnLookup(aa+1),x,y,z-1.0),pnGradient(pnLookup(ba+1),x-1.0,y,z-1.0)),
              pnMix(u,pnGradient(pnLookup(ab+1),x,y-1.0,z-1.0),pnGradient(pnLookup(bb+1),x-1.0,y-1.0,z-1.0))))
