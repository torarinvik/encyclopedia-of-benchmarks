module nbench_fourier_coefficients
import math
const max_n=16
const invalid_result=f64(-1e300)
fn term(x f64,omega f64,select int)f64{base:=math.pow(x+1.0,x);if select==0{return base};if select==1{return base*math.cos(omega*x)};return base*math.sin(omega*x)}
fn integrate(omega f64,select int)f64{mut x:=0.0;dx:=(2.0-0.0)/200.0;mut value:=term(0.0,omega,select)/2.0;mut steps:=200;if steps!=1{steps--;for{steps--;if steps==0{break};x+=dx;value+=term(x,omega,select)}};return(value+term(2.0,omega,select)/2.0)*dx}
@[export: 'nbench_fourier_coefficients']
pub fn nbench_fourier_coefficients(input &i64,length usize)f64{
	unsafe{if input==nil||length<1||length>2{return invalid_result};raw:=input[0];if raw<1||raw>max_n||length!=1{return invalid_result};n:=int(raw);mut a:=[max_n]f64{init:0};mut b:=[max_n]f64{init:0};a[0]=integrate(0.0,0)/2.0
		for i in 1 .. n{omega:=3.1415926535897932*f64(i);a[i]=integrate(omega,1);b[i]=integrate(omega,2)}
		mut checksum:=0.0;for i in 0 .. n{checksum+=f64(i+1)*a[i]};for i in 1 .. n{checksum+=f64(i)*b[i]};if !checksum.is_finite(){return invalid_result};return checksum}
}
