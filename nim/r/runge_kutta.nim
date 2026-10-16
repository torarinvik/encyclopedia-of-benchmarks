import std/math

const Invalid = -1.0e300
proc finite(x: float64): bool = classify(x) notin {fcNan, fcInf, fcNegInf}
proc deriv(id: int64, x, y: float64): float64 =
  case id
  of 0: y
  of 1: x
  of 2: x + y
  of 3: (x - y) / 2.0
  else: 1.0 + y * y
proc rkStep(id: int64, x, y, h: float64): tuple[value: float64, ok: bool] =
  let k1 = deriv(id, x, y)
  let k2 = deriv(id, x + 0.5 * h, y + 0.5 * h * k1)
  let k3 = deriv(id, x + 0.5 * h, y + 0.5 * h * k2)
  let k4 = deriv(id, x + h, y + h * k3)
  result.value = y + (1.0 / 6.0) * h * (k1 + 2.0 * k2 + 2.0 * k3 + k4)
  result.ok = finite(k1) and finite(k2) and finite(k3) and finite(k4) and finite(result.value)

proc runge_kutta*(input: ptr int64, length: csize_t): float64 {.cdecl, exportc: "runge_kutta".} =
  if input.isNil or length != 5: return Invalid
  let fid = input[0]; let ym = input[1]; let xm = input[2]; let hm = input[3]; let em = input[4]
  if fid < 0 or fid > 4 or ym < -1_000_000 or ym > 1_000_000 or xm < -1_000_000 or xm > 1_000_000 or em < -1_000_000 or em > 1_000_000 or hm < 10_000 or hm > 250_000 or em <= xm: return Invalid
  let y0 = float64(ym) / 1_000_000.0; let x0 = float64(xm) / 1_000_000.0
  let h = float64(hm) / 1_000_000.0; let ending = float64(em) / 1_000_000.0
  if fid == 4 and (x0 < 0.0 or y0 > 0.0): return Invalid
  let steps = int(ceil((ending - x0) / h))
  if steps < 1 or steps > 64: return Invalid
  var x = x0; var y = y0
  for _ in 0 ..< steps:
    let stage = rkStep(fid, x, y, h)
    if not stage.ok: return Invalid
    y = stage.value; x += h
    if not finite(x): return Invalid
  y
