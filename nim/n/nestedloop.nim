const MaxN = 15'i64

proc nestedloop*(input: int64): int64 {.cdecl, exportc: "nestedloop".} =
  if input < 0 or input > MaxN: return -1
  let n = int(input)
  var count = 0'i64
  for a in 0 ..< n:
    for b in 0 ..< n:
      for c in 0 ..< n:
        for d in 0 ..< n:
          for e in 0 ..< n:
            for f in 0 ..< n:
              inc count
  count
