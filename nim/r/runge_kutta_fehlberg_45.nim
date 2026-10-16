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
proc fehlbergStep(id: int64, x, y, h: float64): tuple[value: float64, ok: bool] =
  let k1 = h * deriv(id, x, y)
  let k2 = h * deriv(id, x + h / 4.0, y + k1 / 4.0)
  let k3 = h * deriv(id, x + (3.0 / 8.0) * h, y + (3.0 / 32.0) * k1 + (9.0 / 32.0) * k2)
  let k4 = h * deriv(id, x + (12.0 / 13.0) * h, y + (1932.0 / 2197.0) * k1 - (7200.0 / 2197.0) * k2 + (7296.0 / 2197.0) * k3)
  let k5 = h * deriv(id, x + h, y + (439.0 / 216.0) * k1 - 8.0 * k2 + (3680.0 / 513.0) * k3 - (845.0 / 4104.0) * k4)
  let k6 = h * deriv(id, x + h / 2.0, y - (8.0 / 27.0) * k1 + 2.0 * k2 - (3544.0 / 2565.0) * k3 + (1859.0 / 4104.0) * k4 - (11.0 / 40.0) * k5)
  result.value = y + (16.0 / 135.0) * k1 + (6656.0 / 12825.0) * k3 + (28561.0 / 56430.0) * k4 - (9.0 / 50.0) * k5 + (2.0 / 55.0) * k6
  result.ok = finite(k1) and finite(k2) and finite(k3) and finite(k4) and finite(k5) and finite(k6) and finite(result.value)

proc runge_kutta_fehlberg_45*(input: ptr int64, length: csize_t): float64 {.cdecl, exportc: "runge_kutta_fehlberg_45".} =
  if input.isNil or length != 5: return Invalid
  let fid = input[0]; let ym = input[1]; let xm = input[2]; let hm = input[3]; let em = input[4]
  if fid < 0 or fid > 4 or ym < -1_000_000 or ym > 1_000_000 or xm < -1_000_000 or xm > 1_000_000 or em < -1_000_000 or em > 1_000_000 or hm < 10_000 or hm > 250_000 or em <= xm: return Invalid
  let y0 = float64(ym) / 1_000_000.0; let x0 = float64(xm) / 1_000_000.0
  let h = float64(hm) / 1_000_000.0; let ending = float64(em) / 1_000_000.0
  if fid == 4 and (x0 < 0.0 or y0 > 0.0): return Invalid
  let steps = int((ending - x0) / h)
  if steps < 1 or steps > 64: return Invalid
  var x = x0; var y = y0
  for _ in 0 ..< steps:
    let stage = fehlbergStep(fid, x, y, h)
    if not stage.ok: return Invalid
    y = stage.value; x = h + x
    if not finite(x): return Invalid
  y
