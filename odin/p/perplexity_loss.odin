package perplexity_loss

import "core:c"
import "core:math"

MAX_BATCH :: 8
MAX_TIME :: 16
MAX_VOCAB :: 16
MAX_INPUT_LENGTH :: 3 + MAX_BATCH * MAX_TIME * (MAX_VOCAB + 1)
INVALID_RESULT :: f64 = -1.0e300

@(export)
perplexity_loss :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length < 3 || length > MAX_INPUT_LENGTH do return INVALID_RESULT
	batch_value, time_value, vocab_value := values[0], values[1], values[2]
	if batch_value < 1 || batch_value > MAX_BATCH || time_value < 1 || time_value > MAX_TIME || vocab_value < 2 || vocab_value > MAX_VOCAB do return INVALID_RESULT
	batch, time, vocab := int(batch_value), int(time_value), int(vocab_value)
	tokens := batch * time
	probability_base := 3 + tokens
	if length != c.size_t(probability_base + tokens * vocab) do return INVALID_RESULT
	for row := 0; row < tokens; row += 1 {
		label := values[3 + row]
		if label < 0 || label >= i64(vocab) do return INVALID_RESULT
		row_sum := i64(0)
		for col := 0; col < vocab; col += 1 {
			p := values[probability_base + row * vocab + col]
			if p < 0 || p > 1_000_000 do return INVALID_RESULT
			row_sum += p
		}
		if row_sum != 1_000_000 do return INVALID_RESULT
	}
	batch_total := f64(0.0)
	for sentence := 0; sentence < batch; sentence += 1 {
		log_total := f64(0.0)
		for step := 0; step < time; step += 1 {
			row := sentence * time + step
			label := int(values[3 + row])
			p := f64(values[probability_base + row * vocab + label]) / 1_000_000.0
			if p < 1e-7 do p = 1e-7
			if p > 1.0 do p = 1.0
			log_total += math.log_f64(p)
		}
		batch_total += math.exp_f64(-(log_total / f64(time)))
	}
	return batch_total / f64(batch)
}
