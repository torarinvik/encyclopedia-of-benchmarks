module binary_indexed_tree

const max_items = 256
const max_operations = 512
const max_input_values = 2 + 3 * max_operations
const value_limit = i64(1_000_000)
const query_offset = i64(131_072_000_001)
const final_offset = i64(512_000_001)

fn lowbit(index int) int { return index & -index }
fn prefix_sum(tree []i32, initial int) i32 {
	mut count := initial
	mut sum := i32(0)
	for count > 0 { sum += tree[count]; count -= lowbit(count) }
	return sum
}

@[export: 'binary_indexed_tree']
pub fn binary_indexed_tree(values &i64, length usize) i64 {
	if values == nil || length < 2 || length > max_input_values { return -1 }
	unsafe {
		n_value := values[0]; op_value := values[1]
		if n_value < 2 || n_value > max_items || (n_value & (n_value - 1)) != 0 || op_value < 0 || op_value > max_operations { return -1 }
		n := int(n_value); operations := int(op_value)
		if length != usize(2 + 3 * operations) { return -1 }
		for op in 0 .. operations {
			at := 2 + 3 * op
			code := values[at]; first := values[at + 1]; second := values[at + 2]
			if code == 0 { if first < 0 || first >= n_value || second < -value_limit || second > value_limit { return -1 } }
			else if code == 1 { if first < 0 || second < first || second >= n_value { return -1 } }
			else { return -1 }
		}
		mut data := []i32{len: max_items}
		mut tree := []i32{len: max_items + 2}
		mut checksum := i64(0)
		for op in 0 .. operations {
			at := 2 + 3 * op
			code := values[at]; first := int(values[at + 1]); second := i32(values[at + 2])
			if code == 0 {
				data[first] += second
				mut start := first + 1
				for start <= n + 1 { tree[start] += second; start += lowbit(start) }
			} else {
				result := prefix_sum(tree, int(second) + 1) - prefix_sum(tree, first)
				checksum += i64(op + 1) * (i64(result) + query_offset)
			}
		}
		for i in 0 .. n { checksum += i64(operations + i + 1) * (i64(data[i]) + final_offset) }
		return checksum
	}
}
