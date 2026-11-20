import std/math

const MaxN = 6
const MaxInputLength = 39
const MaxSweeps = 128
const Tolerance = 1.0e-14

proc one_sided_jacobi_svd*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "one_sided_jacobi_svd".} =
  if input == nil or length < 3 or length > MaxInputLength.csize_t: return -1
  let m64 = input[0]
  let n64 = input[1]
  if n64 < 1 or n64 > MaxN or m64 < n64 or m64 > MaxN: return -1
  let m = int(m64)
  let n = int(n64)
  if int(length) != 2 + m * n: return -1
  var a: array[36, float64]
  for r in 0 ..< m:
    for col in 0 ..< n:
      let x = input[2 + r * n + col]
      if x < -8 or x > 8: return -1
      a[r * n + col] = float64(x)
  var converged = false
  for sweep in 0 ..< MaxSweeps:
    var changed = false
    for p in 0 ..< n:
      for q in p + 1 ..< n:
        var alpha, beta, gamma = 0.0
        for r in 0 ..< m:
          let x = a[r * n + p]
          let y = a[r * n + q]
          alpha += x * x
          beta += y * y
          gamma += x * y
        if alpha == 0.0 or beta == 0.0 or abs(gamma) <= Tolerance * sqrt(alpha * beta): continue
        let tau = (beta - alpha) / (2.0 * gamma)
        let t = if tau == 0.0: 1.0 else: (if tau > 0.0: 1.0 else: -1.0) / (abs(tau) + sqrt(1.0 + tau * tau))
        let c = 1.0 / sqrt(1.0 + t * t)
        let s = c * t
        for r in 0 ..< m:
          let x = a[r * n + p]
          let y = a[r * n + q]
          a[r * n + p] = c * x - s * y
          a[r * n + q] = s * x + c * y
        changed = true
    if not changed:
      converged = true
      break
  if not converged: return -1
  var sigma: array[6, float64]
  for col in 0 ..< n:
    for r in 0 ..< m: sigma[col] += a[r * n + col] * a[r * n + col]
    sigma[col] = sqrt(sigma[col])
  for i in 0 ..< n:
    for j in i + 1 ..< n:
      if sigma[j] > sigma[i]: swap(sigma[i], sigma[j])
  var signature = 0.0
  for i in 0 ..< n: signature += float64(i + 1) * sigma[i]
  int64(signature * 1000.0 + 0.5)
