import math

const max_steps = 8
const max_factors = 3

@[export: 'hjm_forward_path']
pub fn hjm_forward_path(input &f64, input_length usize, mut output &f64, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 7 || input_length > 54 { return -1 }
		if !math.is_finite(input[0]) || input[0] < 2.0 || input[0] > 8.0 || math.floor(input[0]) != input[0] { return -1 }
		if !math.is_finite(input[1]) || input[1] < 1.0 || input[1] > 3.0 || math.floor(input[1]) != input[1] { return -1 }
		steps := int(input[0])
		factors := int(input[1])
		years := input[2]
		if years != 1.0 && years != 2.0 && years != 3.0 { return -1 }
		if input_length != usize(3 + steps + 2*factors*(steps-1)) { return -1 }

		mut yields := [max_steps]f64{}
		mut vols := [max_factors*(max_steps-1)]f64{}
		mut shocks := [(max_steps-1)*max_factors]f64{}
		mut forwards := [max_steps]f64{}
		mut factor_drifts := [max_factors*(max_steps-1)]f64{}
		mut total_drifts := [max_steps-1]f64{}
		mut path := [max_steps*max_steps]f64{}
		mut cursor := 3
		for maturity in 0 .. steps {
			value := input[cursor]
			cursor++
			if !math.is_finite(value) || value < -0.05 || value > 0.20 { return -1 }
			yields[maturity] = value
		}
		for factor in 0 .. factors {
			for maturity in 0 .. steps-1 {
				value := input[cursor]
				cursor++
				if !math.is_finite(value) || value < 0.0 || value > 0.30 { return -1 }
				vols[factor*(max_steps-1)+maturity] = value
			}
		}
		for time in 0 .. steps-1 {
			for factor in 0 .. factors {
				value := input[cursor]
				cursor++
				if !math.is_finite(value) || value < -3.0 || value > 3.0 { return -1 }
				shocks[time*max_factors+factor] = value
			}
		}

		dt := years / f64(steps)
		forwards[0] = yields[0]
		for maturity in 1 .. steps {
			forwards[maturity] = f64(maturity+1)*yields[maturity] - f64(maturity)*yields[maturity-1]
		}
		for factor in 0 .. factors {
			base := factor*(max_steps-1)
			factor_drifts[base] = 0.5*dt*vols[base]*vols[base]
			for maturity in 1 .. steps-1 {
				mut drift := 0.0
				for prior in 0 .. maturity { drift -= factor_drifts[base+prior] }
				mut prefix_volatility := 0.0
				for prior in 0 .. maturity+1 { prefix_volatility += vols[base+prior] }
				drift += 0.5*dt*prefix_volatility*prefix_volatility
				factor_drifts[base+maturity] = drift
			}
		}
		for maturity in 0 .. steps-1 {
			for factor in 0 .. factors { total_drifts[maturity] += factor_drifts[factor*(max_steps-1)+maturity] }
		}
		for maturity in 0 .. steps { path[maturity] = forwards[maturity] }
		root_dt := math.sqrt(dt)
		for time in 1 .. steps {
			for maturity in 0 .. steps-time {
				mut total_shock := 0.0
				for factor in 0 .. factors { total_shock += vols[factor*(max_steps-1)+maturity]*shocks[(time-1)*max_factors+factor] }
				path[time*steps+maturity] = path[(time-1)*steps+maturity+1] + total_drifts[maturity]*dt + root_dt*total_shock
			}
		}
		needed := steps*steps
		if output == nil || output_capacity < needed { return -2 }
		for index in 0 .. needed { output[index] = path[index] }
		return i64(needed)
	}
}
