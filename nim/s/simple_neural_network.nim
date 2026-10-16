import math
const InvalidResult=-1.0e300
proc simple_neural_network*(values:ptr UncheckedArray[int64],length:csize_t):float64 {.cdecl,exportc:"simple_neural_network".}=
  if values==nil or length!=3:return InvalidResult
  let expected=values[0];let initial=values[1];let count=values[2]
  if expected<0 or expected>100 or initial<1 or initial>199 or initial mod 2!=1 or count<1 or count>65536:return InvalidResult
  let target=float64(expected)/100.0;var weight=float64(initial);var layer=0.0
  for _ in 0..<int(count):layer=1.0/(1.0+exp(-0.02*weight));let error=target-layer;let delta=error*layer*(1.0-layer);weight+=0.02*delta
  layer*100.0
