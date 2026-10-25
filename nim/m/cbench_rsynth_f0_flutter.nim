import std/math

proc cbench_rsynth_f0_flutter*(input: ptr UncheckedArray[int64], n: csize_t): int64 {.cdecl, exportc: "cbench_rsynth_f0_flutter".} =
  if input == nil or n < 1 or n > 4: return -1
  if n != 3 or input[0] < 0 or input[0] > 20_000 or input[1] < 0 or input[1] > 100 or input[2] < 0 or input[2] > 1_000_000: return -1
  let f0=input[0];let flutter=input[1];let t=input[2];let original=f0 div 10
  let pi=3.1415927
  let fla=float64(flutter)/50.0
  let flb=float64(original)/100.0
  let flc=sin(2.0*pi*12.7*float64(t))
  let fld=sin(2.0*pi*7.1*float64(t))
  let fle=sin(2.0*pi*4.7*float64(t))
  let delta=fla*flb*(flc+fld+fle)*10.0
  f0+int64(delta)
