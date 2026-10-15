## Count distinct prime divisors using factor-2 removal and odd trial divisors.
proc hardy_ramanujanalgo*(value: int64): int64 {.cdecl, exportc: "hardy_ramanujanalgo".} =
  if value < 1 or value > 2_147_483_647: return -1

  var remaining = value
  var count: int64 = 0
  if remaining mod 2 == 0: inc count
  while remaining mod 2 == 0: remaining = remaining div 2

  var factor: int64 = 3
  while factor <= remaining div factor:
    if remaining mod factor == 0:
      inc count
      while remaining mod factor == 0: remaining = remaining div factor
    factor += 2
  if remaining > 2: inc count
  count
