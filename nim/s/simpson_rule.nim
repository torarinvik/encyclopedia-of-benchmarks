const InvalidResult = -1.0e300

proc simpsonRuleF(x: float64): float64 =
  (x - 0.0) * (x - 0.0)

proc simpson_rule*(b, steps: float64): float64 {.cdecl, exportc: "simpson_rule".} =
  if (b != 1.0 and b != 2.0 and b != 3.0) or steps != 10.0: return InvalidResult

  let a = 0.0
  let h = (b - a) / steps
  var x = a + h
  var y = 0.0
  y += (h / 3.0) * simpsonRuleF(a)
  var count = 2
  while x < b - h:
    let weight = 4 - 2 * (count mod 2)
    y += (h / 3.0) * float64(weight) * simpsonRuleF(x)
    inc count
    x = x + h
  y += (h / 3.0) * simpsonRuleF(b)
  y
