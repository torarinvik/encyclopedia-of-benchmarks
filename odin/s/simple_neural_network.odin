package simple_neural_network
import "core:math"
INVALID :: -1.0e300
@(export)
simple_neural_network :: proc "c" (values:[^]i64,length:c.size_t)->f64 {if values==nil||length!=3 do return INVALID;expected,initial,count:=values[0],values[1],values[2];if expected<0||expected>100||initial<1||initial>199||initial%2!=1||count<1||count>65536 do return INVALID;target:=f64(expected)/100.0;weight:=f64(initial);layer:=0.0;for i:=i64(0);i<count;i+=1{layer=1.0/(1.0+math.exp_f64(-0.02*weight));error:=target-layer;delta:=error*layer*(1.0-layer);weight+=0.02*delta};return layer*100.0}
