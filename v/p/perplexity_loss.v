module perplexity_loss

import math

const max_batch = 8
const max_time = 16
const max_vocab = 16
const max_input_length = 3 + max_batch * max_time * (max_vocab + 1)
const invalid_result = -1.0e300

@[export: 'perplexity_loss']
pub fn perplexity_loss(values &i64, length usize) f64 {
	if unsafe { values == nil } || length < 3 || length > max_input_length { return invalid_result }
	unsafe {
		batch_value := values[0]
		time_value := values[1]
		vocab_value := values[2]
		if batch_value < 1 || batch_value > max_batch || time_value < 1 || time_value > max_time || vocab_value < 2 || vocab_value > max_vocab { return invalid_result }
		batch, time, vocab := int(batch_value), int(time_value), int(vocab_value)
		tokens := batch * time
		probability_base := 3 + tokens
		if length != probability_base + tokens * vocab { return invalid_result }
		for row in 0 .. tokens {
			label := values[3 + row]
			if label < 0 || label >= i64(vocab) { return invalid_result }
			mut row_sum := i64(0)
			for c in 0 .. vocab {
				p := values[probability_base + row * vocab + c]
				if p < 0 || p > 1_000_000 { return invalid_result }
				row_sum += p
			}
			if row_sum != 1_000_000 { return invalid_result }
		}
		mut batch_total := 0.0
		for sentence in 0 .. batch {
			mut log_total := 0.0
			for step in 0 .. time {
				row := sentence * time + step
				label := int(values[3 + row])
				mut probability := f64(values[probability_base + row * vocab + label]) / 1_000_000.0
				if probability < 1e-7 { probability = 1e-7 }
				if probability > 1.0 { probability = 1.0 }
				log_total += math.log(probability)
			}
			batch_total += math.exp(-(log_total / f64(time)))
		}
		return batch_total / f64(batch)
	}
}
