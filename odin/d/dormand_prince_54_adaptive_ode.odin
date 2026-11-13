package dormand_prince_54_adaptive_ode

import "core:c"
import "core:math"

MAX_INPUT_LENGTH :: 7

exact_integer :: proc(value: f64, low, high: i64) -> bool {
	if math.is_nan(value) || math.is_inf(value) || value < f64(low) || value > f64(high) do return false
	return f64(i64(value)) == value
}
rhs :: proc(id: i64, x, y: f64) -> f64 {
	if id == 0 do return y
	if id == 1 do return x+y
	if id == 2 do return math.sin_f64(x)
	return 1.0
}
trial :: proc(id: i64,x,y,h,k1: f64) -> (f64,f64,f64,bool) {
	k2:=rhs(id,x+h*(1.0/5.0),y+h*((1.0/5.0)*k1))
	k3:=rhs(id,x+h*(3.0/10.0),y+h*((3.0/40.0)*k1+(9.0/40.0)*k2))
	k4:=rhs(id,x+h*(4.0/5.0),y+h*((44.0/45.0)*k1-(56.0/15.0)*k2+(32.0/9.0)*k3))
	k5:=rhs(id,x+h*(8.0/9.0),y+h*((19372.0/6561.0)*k1-(25360.0/2187.0)*k2+(64448.0/6561.0)*k3-(212.0/729.0)*k4))
	k6:=rhs(id,x+h,y+h*((9017.0/3168.0)*k1-(355.0/33.0)*k2+(46732.0/5247.0)*k3+(49.0/176.0)*k4-(5103.0/18656.0)*k5))
	y5:=y+h*((35.0/384.0)*k1+(500.0/1113.0)*k3+(125.0/192.0)*k4-(2187.0/6784.0)*k5+(11.0/84.0)*k6)
	k7:=rhs(id,x+h,y5)
	error:=h*((71.0/57600.0)*k1-(71.0/16695.0)*k3+(71.0/1920.0)*k4-(17253.0/339200.0)*k5+(22.0/525.0)*k6-(1.0/40.0)*k7)
	ok:=!math.is_nan(y5)&&!math.is_inf(y5)&&!math.is_nan(error)&&!math.is_inf(error)&&!math.is_nan(k7)&&!math.is_inf(k7)
	return y5,error,k7,ok
}
integrate :: proc(id: i64, initial_y, initial_x, ending: f64, exponent, attempts: i64) -> (i64,f64) {
	tolerance:=math.pow_f64(10.0,-f64(exponent))
	x,y:=initial_x,initial_y
	h:=math.min((ending-initial_x)/4.0,0.25)
	k1:=rhs(id,x,y)
	for attempt:=i64(0);attempt<attempts;attempt+=1 {
		remaining:=ending-x
		if remaining<=0.0 do return 1,y
		step:=math.min(math.min(h,0.25),remaining)
		if step<=0.0||x+step==x do return -3,0.0
		y5,error,k7,ok:=trial(id,x,y,step,k1)
		if !ok do return -3,0.0
		scale:=tolerance*(1.0+math.max(math.abs_f64(y),math.abs_f64(y5)))
		norm:=math.abs_f64(error)/scale
		if math.is_nan(norm)||math.is_inf(norm) do return -3,0.0
		if norm<=1.0 {
			if step==remaining do x=ending else x+=step
			y=y5;k1=k7
			if x>=ending { if math.is_nan(y)||math.is_inf(y) do return -3,0.0;return 1,y }
		}
		factor:=5.0
		if norm!=0.0 do factor=0.9*math.pow_f64(norm,-0.2)
		h=step*math.min(5.0,math.max(0.2,factor))
	}
	return -3,0.0
}

@(export)
dormand_prince_54_adaptive_ode :: proc "c" (input: [^]f64, input_length: c.size_t,
	output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input==nil||input_length!=6||input_length>MAX_INPUT_LENGTH do return -1
	if !exact_integer(input[0],0,3)||!exact_integer(input[1],-1000,1000)||!exact_integer(input[2],-1000,1000)||!exact_integer(input[3],-1000,1000)||!exact_integer(input[4],8,9)||!exact_integer(input[5],64,128)||input[3]<=input[2] do return -1
	if output==nil||output_capacity<1 do return -2
	status,value:=integrate(i64(input[0]),input[1]/1000.0,input[2]/1000.0,input[3]/1000.0,i64(input[4]),i64(input[5]))
	if status!=1||math.is_nan(value)||math.is_inf(value) do return -3
	output[0]=value
	return 1
}
