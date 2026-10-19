package nbench_fourier_coefficients
import "core:c"
import "core:math"
MAX_N :: 16
INVALID_RESULT :: -1e300
term :: proc "contextless" (x,omega:f64,select:int)->f64{base:=math.pow(x+1.0,x);if select==0 do return base;if select==1 do return base*math.cos(omega*x);return base*math.sin(omega*x)}
integrate :: proc "contextless" (omega:f64,select:int)->f64{x:=0.0;dx:=(2.0-0.0)/200.0;value:=term(0.0,omega,select)/2.0;steps:=200;if steps!=1{steps-=1;for{steps-=1;if steps==0 do break;x+=dx;value+=term(x,omega,select)}};return(value+term(2.0,omega,select)/2.0)*dx}
@(export)
nbench_fourier_coefficients :: proc "c" (input:[^]i64,length:c.size_t)->f64{
	if input==nil||length<1||length>2 do return INVALID_RESULT
	raw:=input[0]
	if raw<1||raw>MAX_N||length!=1 do return INVALID_RESULT
	n:=int(raw);a:[MAX_N]f64;b:[MAX_N]f64;a[0]=integrate(0.0,0)/2.0
	for i:=1;i<n;i+=1{omega:=3.1415926535897932*f64(i);a[i]=integrate(omega,1);b[i]=integrate(omega,2)}
	checksum:=0.0;for i:=0;i<n;i+=1{checksum+=f64(i+1)*a[i]};for i:=1;i<n;i+=1{checksum+=f64(i)*b[i]}
	if !math.is_finite(checksum) do return INVALID_RESULT
	return checksum
}
