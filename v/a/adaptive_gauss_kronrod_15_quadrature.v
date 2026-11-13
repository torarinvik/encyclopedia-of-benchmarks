import math

const max_intervals = 16

struct PairEstimate {
	kronrod f64
	gauss f64
}

fn gk_sample(id i64, x f64) f64 {
	if id == 0 { return math.exp(4.0*x) }
	if id == 1 { return math.sin(10.0*x) }
	if id == 2 { return 1.0/(1.0+9.0*x*x) }
	x2 := x*x
	x4 := x2*x2
	x8 := x4*x4
	return x8*x4*x2
}

fn gk_pair(id i64, a f64, b f64) PairEstimate {
	nodes := [7]f64{0.9914553711208126392,0.9491079123427585245,0.8648644233597690728,
		0.7415311855993944399,0.5860872354676911303,0.4058451513773971669,0.2077849550078984676}
	kw := [7]f64{0.022935322010529225,0.06309209262997855,0.10479001032225018,
		0.14065325971552592,0.16900472663926790,0.19035057806478541,0.20443294007529889}
	gw := [3]f64{0.12948496616886969,0.27970539148927667,0.38183005050511894}
	center := (a+b)*0.5
	half := (b-a)*0.5
	fc := gk_sample(id, center)
	mut ks := 0.2094821410847278280*fc
	mut gs := 0.4179591836734693878*fc
	for i in 0..7 {
		offset := half*nodes[i]
		pair := gk_sample(id, center-offset)+gk_sample(id, center+offset)
		ks += kw[i]*pair
		if i == 1 { gs += gw[0]*pair }
		if i == 3 { gs += gw[1]*pair }
		if i == 5 { gs += gw[2]*pair }
	}
	return PairEstimate{kronrod: half*ks, gauss: half*gs}
}

fn exact_integer(x f64, low i64, high i64) bool {
	return x.is_finite() && x >= f64(low) && x <= f64(high) && f64(i64(x)) == x
}

@[export: 'adaptive_gauss_kronrod_15_quadrature']
pub fn adaptive_gauss_kronrod_15_quadrature(input &f64, input_length usize,
	mut output &f64, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length != 5 || input_length > 6 { return -1 }
		if !exact_integer(input[0],0,3) || !exact_integer(input[1],-1000000,1000000) ||
			!exact_integer(input[2],-1000000,1000000) || !exact_integer(input[3],6,8) ||
			!exact_integer(input[4],1,max_intervals) { return -1 }
		id := i64(input[0]); a_micro := i64(input[1]); b_micro := i64(input[2])
		exponent := i64(input[3]); limit := i64(input[4])
		if a_micro > b_micro { return -1 }
		if output == nil || output_capacity < 1 { return -2 }
		a := f64(a_micro)/1000000.0
		b := f64(b_micro)/1000000.0
		if a == b { output[0] = 0.0; return 1 }
		mut lefts := [max_intervals]f64{}
		mut rights := [max_intervals]f64{}
		mut values := [max_intervals]f64{}
		mut errors := [max_intervals]f64{}
		initial := gk_pair(id,a,b)
		lefts[0]=a; rights[0]=b; values[0]=initial.kronrod; errors[0]=math.abs(initial.kronrod-initial.gauss)
		mut count := 1
		mut tolerance := 1.0
		for _ in 0..exponent { tolerance *= 0.1 }
		for {
			mut total := f64(0.0); mut error := f64(0.0)
			for i in 0..count { total += values[i]; error += errors[i] }
			scale := if math.abs(total) > 1.0 { math.abs(total) } else { 1.0 }
			if error <= tolerance*scale {
				if !total.is_finite() { return -1 }
				output[0]=total
				return 1
			}
			if count >= limit { return -3 }
			mut best := 0
			for i in 1..count {
				if errors[i] > errors[best] || (errors[i] == errors[best] && lefts[i] < lefts[best]) { best=i }
			}
			left := lefts[best]; right := rights[best]; middle := (left+right)*0.5
			lhs := gk_pair(id,left,middle); rhs := gk_pair(id,middle,right)
			lefts[best]=left; rights[best]=middle; values[best]=lhs.kronrod; errors[best]=math.abs(lhs.kronrod-lhs.gauss)
			lefts[count]=middle; rights[count]=right; values[count]=rhs.kronrod; errors[count]=math.abs(rhs.kronrod-rhs.gauss)
			count++
		}
	}
}
