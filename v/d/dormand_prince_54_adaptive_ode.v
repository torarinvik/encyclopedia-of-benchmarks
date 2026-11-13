import math

fn exact_integer(value f64, low i64, high i64) bool {
	return value.is_finite() && value >= f64(low) && value <= f64(high) && f64(i64(value)) == value
}

fn rhs(id i64, x f64, y f64) f64 {
	if id == 0 { return y }
	if id == 1 { return x+y }
	if id == 2 { return math.sin(x) }
	return 1.0
}

fn trial(id i64, x f64, y f64, h f64, k1 f64, mut y5 &f64, mut error &f64, mut k7 &f64) bool {
	k2 := rhs(id,x+h*(1.0/5.0),y+h*((1.0/5.0)*k1))
	k3 := rhs(id,x+h*(3.0/10.0),y+h*((3.0/40.0)*k1+(9.0/40.0)*k2))
	k4 := rhs(id,x+h*(4.0/5.0),y+h*((44.0/45.0)*k1-(56.0/15.0)*k2+(32.0/9.0)*k3))
	k5 := rhs(id,x+h*(8.0/9.0),y+h*((19372.0/6561.0)*k1-(25360.0/2187.0)*k2+(64448.0/6561.0)*k3-(212.0/729.0)*k4))
	k6 := rhs(id,x+h,y+h*((9017.0/3168.0)*k1-(355.0/33.0)*k2+(46732.0/5247.0)*k3+(49.0/176.0)*k4-(5103.0/18656.0)*k5))
	y5 = y+h*((35.0/384.0)*k1+(500.0/1113.0)*k3+(125.0/192.0)*k4-(2187.0/6784.0)*k5+(11.0/84.0)*k6)
	k7 = rhs(id,x+h,y5)
	error = h*((71.0/57600.0)*k1-(71.0/16695.0)*k3+(71.0/1920.0)*k4-(17253.0/339200.0)*k5+(22.0/525.0)*k6-(1.0/40.0)*k7)
	return y5.is_finite() && error.is_finite() && k7.is_finite()
}

fn integrate(id i64, initial_y f64, initial_x f64, ending f64, exponent i64, attempts i64, mut result &f64) bool {
	tolerance := math.pow(10.0,-f64(exponent))
	mut x := initial_x
	mut y := initial_y
	mut h := math.min((ending-initial_x)/4.0,0.25)
	mut k1 := rhs(id,x,y)
	for _ in 0 .. attempts {
		remaining := ending-x
		if remaining <= 0.0 { result = y; return true }
		step := math.min(math.min(h,0.25),remaining)
		if step <= 0.0 || x+step == x { return false }
		mut y5 := 0.0
		mut error := 0.0
		mut k7 := 0.0
		if !trial(id,x,y,step,k1,mut y5,mut error,mut k7) { return false }
		scale := tolerance*(1.0+math.max(math.abs(y),math.abs(y5)))
		norm := math.abs(error)/scale
		if !norm.is_finite() { return false }
		if norm <= 1.0 {
			if step == remaining { x = ending } else { x += step }
			y = y5
			k1 = k7
			if x >= ending { result = y; return y.is_finite() }
		}
		mut factor := 5.0
		if norm != 0.0 { factor = 0.9*math.pow(norm,-0.2) }
		h = step*math.min(5.0,math.max(0.2,factor))
	}
	return false
}

@[export: 'dormand_prince_54_adaptive_ode']
pub fn dormand_prince_54_adaptive_ode(input &f64, input_length usize, mut output &f64, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length != 6 || input_length > 7 { return -1 }
		if !exact_integer(input[0],0,3) || !exact_integer(input[1],-1000,1000) ||
			!exact_integer(input[2],-1000,1000) || !exact_integer(input[3],-1000,1000) ||
			!exact_integer(input[4],8,9) || !exact_integer(input[5],64,128) || input[3] <= input[2] { return -1 }
		if output == nil || output_capacity < 1 { return -2 }
		mut result := 0.0
		if !integrate(i64(input[0]),input[1]/1000.0,input[2]/1000.0,input[3]/1000.0,i64(input[4]),i64(input[5]),mut result) { return -3 }
		output[0] = result
		return 1
	}
}
