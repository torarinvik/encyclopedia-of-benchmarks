module unshuffle_sort

const max_items = 1024
const no_node = u32(max_items)

fn pile_less(pile_front &u32, values &i64, left u32, right u32) bool {
	unsafe {
		left_node := pile_front[int(left)]
		right_node := pile_front[int(right)]
		if values[int(left_node)] != values[int(right_node)] {
			return values[int(left_node)] < values[int(right_node)]
		}
	}
	return left < right
}

fn sift_down(pile_front &u32, values &i64, mut heap &u32, heap_size u32, start u32) {
	unsafe {
		mut position := start
		for position * 2 + 1 < heap_size {
			mut child := position * 2 + 1
			if child + 1 < heap_size
				&& pile_less(pile_front, values, heap[int(child + 1)], heap[int(child)]) {
				child++
			}
			if !pile_less(pile_front, values, heap[int(child)], heap[int(position)]) {
				break
			}
			temporary := heap[int(position)]
			heap[int(position)] = heap[int(child)]
			heap[int(child)] = temporary
			position = child
		}
	}
}

@[export: 'unshuffle_sort']
pub fn unshuffle_sort(mut values &i64, mut scratch &i64, length usize) {
	unsafe {
		if values == nil || scratch == nil || length < 2 || length > max_items {
			return
		}
		mut previous := [max_items]u32{}
		mut next := [max_items]u32{}
		mut pile_front := [max_items]u32{}
		mut pile_back := [max_items]u32{}
		mut heap := [max_items]u32{}
		mut pile_count := u32(0)

		for node in 0 .. int(length) {
			previous[node] = no_node
			next[node] = no_node
			mut pile := u32(0)
			for pile < pile_count {
				front := pile_front[int(pile)]
				back := pile_back[int(pile)]
				if values[node] <= values[int(front)] {
					next[node] = front
					previous[int(front)] = u32(node)
					pile_front[int(pile)] = u32(node)
					break
				}
				if values[node] >= values[int(back)] {
					previous[node] = back
					next[int(back)] = u32(node)
					pile_back[int(pile)] = u32(node)
					break
				}
				pile++
			}
			if pile == pile_count {
				pile_front[int(pile_count)] = u32(node)
				pile_back[int(pile_count)] = u32(node)
				pile_count++
			}
		}

		mut heap_size := u32(0)
		for pile := u32(0); pile < pile_count; pile++ {
			mut position := heap_size
			heap[int(position)] = pile
			heap_size++
			for position > 0 {
				parent := (position - 1) / 2
				if !pile_less(&pile_front[0], values, heap[int(position)], heap[int(parent)]) {
					break
				}
				temporary := heap[int(position)]
				heap[int(position)] = heap[int(parent)]
				heap[int(parent)] = temporary
				position = parent
			}
		}

		mut output := 0
		for heap_size > 0 {
			pile := heap[0]
			node := pile_front[int(pile)]
			scratch[output] = values[int(node)]
			output++
			successor := next[int(node)]
			if successor != no_node {
				previous[int(successor)] = no_node
				next[int(node)] = no_node
				pile_front[int(pile)] = successor
			} else {
				pile_front[int(pile)] = no_node
				pile_back[int(pile)] = no_node
				heap_size--
				if heap_size > 0 {
					heap[0] = heap[int(heap_size)]
				}
			}
			if heap_size > 0 {
				sift_down(&pile_front[0], values, &heap[0], heap_size, 0)
			}
		}
		for index in 0 .. int(length) {
			values[index] = scratch[index]
		}
	}
}
