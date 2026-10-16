module inorder_successor_of_bst

const max_nodes = 64
const max_input_length = usize(67)

@[export: 'inorder_successor_of_bst']
pub fn inorder_successor_of_bst(input &i64, length usize) i64 {
	if isnil(input) || length < 2 || length > max_input_length { return -1 }
	count_value := unsafe { input[0] }
	target := unsafe { input[1] }
	if count_value < 0 || count_value > max_nodes || target < 1 || target > 2_147_483_647 { return -1 }
	count := int(count_value)
	if length != usize(count + 2) { return -1 }

	mut keys := []i64{len: count}
	mut left := []int{len: count, init: -1}
	mut right := []int{len: count, init: -1}
	for index in 0 .. count {
		key := unsafe { input[index + 2] }
		if key < 1 || key > 2_147_483_647 { return -1 }
		for previous in 0 .. index {
			if keys[previous] == key { return -1 }
		}
		keys[index] = key
	}

	mut root := -1
	for index in 0 .. count {
		if root < 0 {
			root = index
			continue
		}
		mut current := root
		for {
			if keys[index] <= keys[current] {
				if left[current] < 0 {
					left[current] = index
					break
				}
				current = left[current]
			} else {
				if right[current] < 0 {
					right[current] = index
					break
				}
				current = right[current]
			}
		}
	}

	mut current := root
	for current >= 0 && keys[current] != target {
		if target > keys[current] { current = right[current] } else { current = left[current] }
	}
	if current < 0 { return 0 }
	if right[current] >= 0 {
		mut successor := right[current]
		for left[successor] >= 0 { successor = left[successor] }
		return keys[successor]
	}
	mut successor := -1
	mut ancestor := root
	for ancestor >= 0 && ancestor != current {
		if keys[current] < keys[ancestor] {
			successor = ancestor
			ancestor = left[ancestor]
		} else {
			ancestor = right[ancestor]
		}
	}
	if successor < 0 { return 0 }
	return keys[successor]
}
