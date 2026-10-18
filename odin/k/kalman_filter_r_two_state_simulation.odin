package kalman_filter_r_two_state_simulation

import "core:c"
import "core:math"

MAX_OBSERVATIONS :: 12
MAX_OUTPUT_ELEMENTS :: 30

@(export)
kalman_filter_r_two_state_simulation :: proc "c" (input: [^]f64, input_length: c.size_t,
	output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 1 || input_length > MAX_OBSERVATIONS do return -1
	observation_count := int(input_length)
	for index := 0; index < observation_count; index += 1 {
		value := input[index]
		if math.is_nan(value) || math.is_inf(value) || value < -1000.0 || value > 1000.0 do return -1
	}

	required := 2*observation_count + 6
	if required > MAX_OUTPUT_ELEMENTS do return -1
	staged: [MAX_OUTPUT_ELEMENTS]f64 = {}
	state_0 := input[0]
	state_1 := 0.0
	covariance_00 := 1.0
	covariance_01 := 0.0
	covariance_10 := 0.0
	covariance_11 := 1.0
	state_pred_0, state_pred_1: f64 = 0.0, 0.0
	covariance_pred_00, covariance_pred_01 := f64(0.0), f64(0.0)
	covariance_pred_10, covariance_pred_11 := f64(0.0), f64(0.0)

	for step := 0; step < observation_count; step += 1 {
		state_pred_0 = state_0
		state_pred_1 = state_0 + state_1

		temp_00 := covariance_00
		temp_01 := covariance_01
		temp_10 := covariance_00 + covariance_10
		temp_11 := covariance_01 + covariance_11
		covariance_pred_00 = temp_00 + 0.0001
		covariance_pred_01 = temp_00 + temp_01
		covariance_pred_10 = temp_10
		covariance_pred_11 = temp_10 + temp_11 + 0.0001

		innovation := covariance_pred_00 + 0.1
		gain_0 := covariance_pred_00 / innovation
		gain_1 := covariance_pred_10 / innovation
		residual := input[step] - state_pred_0
		state_0 = state_pred_0 + gain_0*residual
		state_1 = state_pred_1 + gain_1*residual
		staged[2*step] = state_0
		staged[2*step+1] = state_1

		covariance_00 = (1.0-gain_0)*covariance_pred_00 + covariance_pred_10
		covariance_01 = (1.0-gain_0)*covariance_pred_01 + covariance_pred_11
		covariance_10 = (1.0-gain_1)*covariance_pred_00 + covariance_pred_10
		covariance_11 = (1.0-gain_1)*covariance_pred_01 + covariance_pred_11
	}

	position := 2 * observation_count
	staged[position] = state_pred_0
	staged[position+1] = state_pred_1
	staged[position+2] = covariance_pred_00
	staged[position+3] = covariance_pred_10
	staged[position+4] = covariance_pred_01
	staged[position+5] = covariance_pred_11
	if output == nil || output_capacity < c.size_t(required) do return -2
	for index := 0; index < required; index += 1 { output[index] = staged[index] }
	return i64(required)
}
