package bitmap_block_allocation
import "core:c"
MAX_BITS :: 4096
MAX_OPS :: 32
MAX_OUTPUT :: MAX_BITS / 8
@(export)
bitmap_block_allocation :: proc "c" (values: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if values == nil || length < 2 || length > c.size_t(2+2*MAX_OPS) do return -1
	raw_bits, raw_ops := values[0], values[1]
	if raw_bits < 1 || raw_bits > MAX_BITS || raw_ops < 0 || raw_ops > MAX_OPS || length != c.size_t(2+2*int(raw_ops)) do return -1
	bits, ops := int(raw_bits), int(raw_ops)
	offsets: [MAX_OPS]int; runs: [MAX_OPS]int
	for i := 0; i < ops; i += 1 {
		o, n := values[2+2*i], values[3+2*i]
		if o < 0 || o > raw_bits || n < 0 || n > raw_bits-o do return -1
		offsets[i], runs[i] = int(o), int(n)
	}
	bitmap: [MAX_BITS]bool
	for b := 0; b < bits; b += 2 do bitmap[b] = true
	for i := 0; i < ops; i += 1 {
		for b := offsets[i]; b < offsets[i]+runs[i]; b += 1 {
			if i % 3 == 0 do bitmap[b] = true
			else if i % 3 == 1 do bitmap[b] = false
			else do bitmap[b] = !bitmap[b]
		}
	}
	byte_count := (bits+7)/8
	if output == nil || capacity < c.size_t(byte_count) do return -2
	for j := 0; j < byte_count; j += 1 {
		packed: u8 = 0
		for bit := 0; bit < 8; bit += 1 {
			index := j*8+bit
			if index < bits && bitmap[index] do packed |= 1 << u32(bit)
		}
		output[j] = packed
	}
	return i64(byte_count)
}
