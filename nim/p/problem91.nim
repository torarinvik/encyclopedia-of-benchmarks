## Count right triangles formed by unordered grid-point pairs and the origin.
const MaxLimit = 50'i64

proc problem91*(limit: int64): int64 {.cdecl, exportc: "problem91".} =
  if limit < 0 or limit > MaxLimit: return -1
  var count = 0'i64
  var x1 = 0'i64
  while x1 <= limit:
    var y1 = 0'i64
    while y1 <= limit:
      var x2 = x1
      while x2 <= limit:
        let firstY2 = if x2 == x1: y1 + 1 else: 0'i64
        var y2 = firstY2
        while y2 <= limit:
          if not ((x1 == 0 and y1 == 0) or (x2 == 0 and y2 == 0)):
            let op = x1 * x1 + y1 * y1
            let oq = x2 * x2 + y2 * y2
            let dx = x1 - x2
            let dy = y1 - y2
            let pq = dx * dx + dy * dy
            if op + oq == pq or op + pq == oq or oq + pq == op:
              inc count
          inc y2
        inc x2
      inc y1
    inc x1
  count
