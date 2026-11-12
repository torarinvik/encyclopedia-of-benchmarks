import math

const MaxParticles = 48
const Boxes = 16
const Order = 32

proc splash2_fmm*(input: ptr UncheckedArray[float64], inputLength: csize_t,
                  output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "splash2_fmm".} =
  if input.isNil or inputLength < csize_t(7) or inputLength > csize_t(145): return -1
  let requested = input[0]
  if requested != requested or requested < 2.0 or requested > float64(MaxParticles) or
      float64(int(requested)) != requested: return -1
  let count = int(requested)
  if inputLength != csize_t(1 + 3 * count): return -1
  var x, y, charge: array[MaxParticles, float64]
  var box: array[MaxParticles, int]
  for i in 0 ..< count:
    let px = input[1 + 3 * i]
    let py = input[2 + 3 * i]
    let q = input[3 + 3 * i]
    if px != px or px < 0.0 or px >= 8.0 or float64(int(px)) != px or
        py != py or py < 0.0 or py >= 8.0 or float64(int(py)) != py or
        q != q or q < -3.0 or q > 3.0 or float64(int(q)) != q: return -1
    x[i] = px; y[i] = py; charge[i] = q
    box[i] = (int(py) div 2) * 4 + int(px) div 2
    for j in 0 ..< i:
      if x[i] == x[j] and y[i] == y[j]: return -1
  if output.isNil or outputCapacity < csize_t(count): return -2

  var mr, mi, lr, li: array[Boxes, array[Order + 1, float64]]
  for i in 0 ..< count:
    let b = box[i]
    let zr = x[i] - float64(2 * (b mod 4) + 1)
    let zi = y[i] - float64(2 * (b div 4) + 1)
    var pr = 1.0; var pi = 0.0
    mr[b][0] += charge[i]
    for k in 1 .. Order:
      let nr = pr * zr - pi * zi
      let ni = pr * zi + pi * zr
      pr = nr; pi = ni
      mr[b][k] += charge[i] * pr
      mi[b][k] += charge[i] * pi

  for target in 0 ..< Boxes:
    let tx = target mod 4; let ty = target div 4
    for source in 0 ..< Boxes:
      let sx = source mod 4; let sy = source div 4
      let dbx = tx - sx; let dby = ty - sy
      if abs(dbx) <= 1 and abs(dby) <= 1: continue
      let dx = 2.0 * float64(dbx); let dy = 2.0 * float64(dby)
      let r2 = dx * dx + dy * dy
      var ir, ii: array[2 * Order + 1, float64]
      ir[0] = 1.0
      let odr = dx / r2; let odi = -dy / r2
      for p in 1 .. 2 * Order:
        ir[p] = ir[p-1] * odr - ii[p-1] * odi
        ii[p] = ir[p-1] * odi + ii[p-1] * odr
      var constant = mr[source][0] * 0.5 * ln(r2)
      for k in 1 .. Order:
        constant -= (mr[source][k] * ir[k] - mi[source][k] * ii[k]) / float64(k)
      lr[target][0] += constant
      for n in 1 .. Order:
        var sr = 0.0; var si = 0.0
        for k in 1 .. Order:
          var choose = 1.0
          for j in 1 .. n: choose *= float64(k + j - 1) / float64(j)
          let scale = choose / float64(k)
          let p = k + n
          sr += scale * (mr[source][k] * ir[p] - mi[source][k] * ii[p])
          si += scale * (mr[source][k] * ii[p] + mi[source][k] * ir[p])
        let qscale = (if n mod 2 == 1: 1.0 else: -1.0) / float64(n)
        let mscale = if n mod 2 == 1: -1.0 else: 1.0
        lr[target][n] += mr[source][0] * qscale * ir[n] - mscale * sr
        li[target][n] += mr[source][0] * qscale * ii[n] - mscale * si

  for i in 0 ..< count:
    let b = box[i]
    let bx = b mod 4; let by = b div 4
    let wr = x[i] - float64(2 * bx + 1)
    let wi = y[i] - float64(2 * by + 1)
    var pr = 1.0; var pi = 0.0
    var value = lr[b][0]
    for n in 1 .. Order:
      let nr = pr * wr - pi * wi
      let ni = pr * wi + pi * wr
      pr = nr; pi = ni
      value += lr[b][n] * pr - li[b][n] * pi
    for j in 0 ..< count:
      if j == i: continue
      let sb = box[j]
      let sx = sb mod 4; let sy = sb div 4
      if abs(bx - sx) > 1 or abs(by - sy) > 1: continue
      let dx = x[j] - x[i]; let dy = y[j] - y[i]
      value += charge[j] * 0.5 * ln(dx * dx + dy * dy)
    output[i] = value
  int64(count)
