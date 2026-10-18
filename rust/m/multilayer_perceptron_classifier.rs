const INPUT_LENGTH: usize = 15;
const MAX_INPUT_LENGTH: usize = 16;
const MAX_OUTPUT_LENGTH: usize = 26;

#[no_mangle]
pub unsafe extern "C" fn multilayer_perceptron_classifier(
    input: *const f64,
    input_length: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length > MAX_INPUT_LENGTH || input_length != INPUT_LENGTH {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(input, input_length) };
    if values.iter().any(|value| !value.is_finite()) {
        return -1;
    }
    if values[0] < 1.0 || values[0] > 12.0 || values[0].fract() != 0.0 {
        return -1;
    }
    let epochs = values[0] as usize;
    let initial_rate = values[1];
    let gamma = values[2];
    if ![0.05, 0.1, 0.2].contains(&initial_rate) || ![0.5, 0.75, 1.0].contains(&gamma) {
        return -1;
    }

    let mut features = [0.0; 8];
    for i in 0..8 {
        let value = values[3 + i];
        if !(-2.0..=2.0).contains(&value) || (value * 4.0).fract() != 0.0 {
            return -1;
        }
        features[i] = value;
    }
    let mut labels = [0usize; 4];
    for i in 0..4 {
        let value = values[11 + i];
        if !(0.0..=2.0).contains(&value) || value.fract() != 0.0 {
            return -1;
        }
        labels[i] = value as usize;
    }

    // First default_rng(42) model after a fresh import, using the source He scales.
    let mut w1 = [
        0.30471707975443135, -1.0399841062404955,
        0.7504511958064572, 0.9405647163912139,
        -1.9510351886538364, -1.302179506862318,
    ];
    let mut w2 = [
        0.12784040316728537, -0.3162425923435822, -0.016801157504288795,
        -0.85304392757358, 0.8793979748628286, 0.7777919354289483,
    ];

    let mut staged = [0.0; MAX_OUTPUT_LENGTH];
    staged[0] = epochs as f64;
    let mut rate = initial_rate;
    for epoch in 0..epochs {
        for row_index in 0..3 {
            let row = [features[row_index * 2], features[row_index * 2 + 1], 1.0];
            let mut z1 = [0.0; 2];
            let mut hidden = [0.0; 2];
            for j in 0..2 {
                let mut sum = 0.0;
                for i in 0..3 {
                    sum += row[i] * w1[i * 2 + j];
                }
                z1[j] = sum;
                hidden[j] = if sum > 0.0 { sum } else { 0.0 };
            }
            let mut z2 = [0.0; 3];
            let mut delta_out = [0.0; 3];
            for k in 0..3 {
                let mut sum = 0.0;
                for j in 0..2 {
                    sum += hidden[j] * w2[j * 3 + k];
                }
                z2[k] = sum;
                let target = if labels[row_index] == k { 0.99 } else { 0.0 };
                delta_out[k] = sum - target;
            }
            let mut delta_hidden = [0.0; 2];
            for j in 0..2 {
                let mut sum = 0.0;
                for k in 0..3 {
                    sum += delta_out[k] * w2[j * 3 + k];
                }
                delta_hidden[j] = sum * if z1[j] > 0.0 { 1.0 } else { 0.0 };
            }
            let mut grad_w1 = [0.0; 6];
            for i in 0..3 {
                for j in 0..2 {
                    grad_w1[i * 2 + j] = row[i] * delta_hidden[j];
                }
            }
            let mut grad_w2 = [0.0; 6];
            for j in 0..2 {
                for k in 0..3 {
                    grad_w2[j * 3 + k] = hidden[j] * delta_out[k];
                }
            }
            for i in 0..6 {
                w1[i] -= rate * grad_w1[i];
            }
            for i in 0..6 {
                w2[i] -= rate * grad_w2[i];
            }
        }

        let test_row = [features[6], features[7], 1.0];
        let mut hidden_test = [0.0; 2];
        for j in 0..2 {
            let mut sum = 0.0;
            for i in 0..3 {
                sum += test_row[i] * w1[i * 2 + j];
            }
            hidden_test[j] = if sum > 0.0 { sum } else { 0.0 };
        }
        let mut test_output = [0.0; 3];
        for k in 0..3 {
            for j in 0..2 {
                test_output[k] += hidden_test[j] * w2[j * 3 + k];
            }
        }
        let mut predicted = 0usize;
        for k in 1..3 {
            if test_output[k] > test_output[predicted] {
                predicted = k;
            }
        }
        staged[1 + epoch] = if predicted == labels[3] { 1.0 } else { 0.0 };
        let mut loss_sum = 0.0;
        for k in 0..3 {
            let target = if labels[3] == k { 0.99 } else { 0.0 };
            let difference = test_output[k] - target;
            loss_sum += difference * difference;
        }
        staged[1 + epochs + epoch] = loss_sum / 2.0;
        rate *= gamma;
    }
    let mut accuracy_sum = 0.0;
    for epoch in 0..epochs {
        accuracy_sum += staged[1 + epoch];
    }
    staged[1 + 2 * epochs] = accuracy_sum / epochs as f64;
    let result_length = 2 * epochs + 2;
    if result_length > MAX_OUTPUT_LENGTH || output.is_null() || output_capacity < result_length {
        return -2;
    }
    for i in 0..result_length {
        unsafe { *output.add(i) = staged[i]; }
    }
    result_length as i64
}
