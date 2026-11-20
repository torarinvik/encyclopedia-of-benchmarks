module skew_binomial_queue

const max_operations = 64
const max_items = 32
const max_nodes = 64
const max_key = i64(1000000)

struct QueueNode {
mut:
	key i64
	serial i64
	item_id int
	rank int
	first_child int
	next_sibling int
	parent int
	alive bool
}

struct SkewBinomialQueue {
mut:
	nodes [64]QueueNode
	active [32]bool
	node_count int
	next_serial i64
}

fn less(q &SkewBinomialQueue, a int, b int) bool {
	x := q.nodes[a]
	y := q.nodes[b]
	if x.key != y.key { return x.key < y.key }
	if x.serial != y.serial { return x.serial < y.serial }
	if x.item_id != y.item_id { return x.item_id < y.item_id }
	return a < b
}

fn root_before(q &SkewBinomialQueue, a int, b int) bool {
	x := q.nodes[a]
	y := q.nodes[b]
	if x.rank != y.rank { return x.rank < y.rank }
	if x.serial != y.serial { return x.serial < y.serial }
	return a < b
}

fn collect_roots(q &SkewBinomialQueue, mut roots [64]int) int {
	mut count := 0
	for i in 0 .. q.node_count {
		if q.nodes[i].alive && q.nodes[i].parent == -1 {
			mut j := count
			for j > 0 && root_before(q, i, roots[j - 1]) {
				roots[j] = roots[j - 1]
				j--
			}
			roots[j] = i
			count++
		}
	}
	return count
}

fn simple_link(mut q SkewBinomialQueue, first int, second int) int {
	mut winner := first
	mut loser := second
	if !less(&q, first, second) { winner, loser = second, first }
	old_children := q.nodes[winner].first_child
	q.nodes[winner].first_child = loser
	q.nodes[loser].next_sibling = old_children
	q.nodes[loser].parent = winner
	q.nodes[winner].rank++
	return winner
}

fn skew_link(mut q SkewBinomialQueue, singleton int, first int, second int) {
	new_rank := q.nodes[first].rank + 1
	mut winner := first
	mut loser := second
	if less(&q, singleton, first) && less(&q, singleton, second) {
		winner = singleton
		q.nodes[winner].first_child = first
		q.nodes[first].next_sibling = second
		q.nodes[second].next_sibling = -1
		q.nodes[first].parent = winner
		q.nodes[second].parent = winner
	} else {
		if !less(&q, first, second) { winner, loser = second, first }
		old_children := q.nodes[winner].first_child
		q.nodes[winner].first_child = singleton
		q.nodes[singleton].next_sibling = loser
		q.nodes[loser].next_sibling = old_children
		q.nodes[singleton].parent = winner
		q.nodes[loser].parent = winner
	}
	q.nodes[winner].parent = -1
	q.nodes[winner].rank = new_rank
}

fn insert_singleton(mut q SkewBinomialQueue, singleton int) {
	q.nodes[singleton].parent = -2
	mut roots := [64]int{}
	root_count := collect_roots(&q, mut roots)
	q.nodes[singleton].next_sibling = -1
	if root_count >= 2 && q.nodes[roots[0]].rank == q.nodes[roots[1]].rank {
		skew_link(mut q, singleton, roots[0], roots[1])
	} else {
		q.nodes[singleton].parent = -1
	}
}

fn normalize_roots(mut q SkewBinomialQueue, mut roots [64]int, root_count int) {
	for i in 1 .. root_count {
		key := roots[i]
		mut j := i
		for j > 0 && root_before(&q, key, roots[j - 1]) {
			roots[j] = roots[j - 1]
			j--
		}
		roots[j] = key
	}
	mut buckets := [64]int{}
	for i in 0 .. max_nodes { buckets[i] = -1 }
	for i in 0 .. root_count {
		mut current := roots[i]
		mut rank := q.nodes[current].rank
		for buckets[rank] >= 0 {
			previous := buckets[rank]
			buckets[rank] = -1
			current = simple_link(mut q, previous, current)
			rank = q.nodes[current].rank
		}
		buckets[rank] = current
	}
}

fn minimum_root(q &SkewBinomialQueue) int {
	mut best := -1
	for i in 0 .. q.node_count {
		if q.nodes[i].alive && q.nodes[i].parent == -1 && (best < 0 || less(q, i, best)) {
			best = i
		}
	}
	return best
}

fn delete_min(mut q SkewBinomialQueue, root int) {
	mut zero_rank := [64]int{}
	mut positive := [64]int{}
	mut zero_count := 0
	mut positive_count := 0
	mut child := q.nodes[root].first_child
	for child >= 0 {
		next := q.nodes[child].next_sibling
		q.nodes[child].parent = -2
		q.nodes[child].next_sibling = -1
		if q.nodes[child].rank == 0 {
			zero_rank[zero_count] = child
			zero_count++
		} else {
			positive[positive_count] = child
			positive_count++
		}
		child = next
	}
	removed_id := q.nodes[root].item_id
	q.active[removed_id] = false
	q.nodes[root].alive = false
	q.nodes[root].parent = -2
	q.nodes[root].item_id = -1
	q.nodes[root].first_child = -1
	q.nodes[root].next_sibling = -1

	for i in 1 .. zero_count {
		key := zero_rank[i]
		mut j := i
		for j > 0 && (q.nodes[zero_rank[j - 1]].serial > q.nodes[key].serial || (q.nodes[zero_rank[j - 1]].serial == q.nodes[key].serial && zero_rank[j - 1] > key)) {
			zero_rank[j] = zero_rank[j - 1]
			j--
		}
		zero_rank[j] = key
	}

	mut roots := [64]int{}
	mut root_count := collect_roots(&q, mut roots)
	for i in 0 .. positive_count {
		q.nodes[positive[i]].parent = -1
		roots[root_count] = positive[i]
		root_count++
	}
	normalize_roots(mut q, mut roots, root_count)
	for i in 0 .. zero_count { insert_singleton(mut q, zero_rank[i]) }
}

fn skew_binomial_queue_impl(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 1 || length > 194 { return -1 }
	unsafe {
		m := input[0]
		if m < 0 || m > max_operations || length != usize(1 + 3 * m) || length > 193 { return -1 }
		mut q := SkewBinomialQueue{}
		mut result := i64(0)
		for operation in 0 .. int(m) {
			offset := 1 + 3 * operation
			opcode := input[offset]
			item_value := input[offset + 1]
			key := input[offset + 2]
			if opcode == 1 {
				if item_value < 0 || item_value >= max_items || key < 0 || key > max_key { return -1 }
				item := int(item_value)
				if q.active[item] || q.node_count >= max_nodes { return -1 }
				node := q.node_count
				q.node_count++
				q.nodes[node] = QueueNode{key: key, serial: q.next_serial, item_id: item, rank: 0, first_child: -1, next_sibling: -1, parent: -2, alive: true}
				q.next_serial++
				q.active[item] = true
				insert_singleton(mut q, node)
			} else if opcode == 2 || opcode == 3 {
				if item_value != 0 || key != 0 { return -1 }
				root := minimum_root(&q)
				if root < 0 { return -1 }
				result += i64(operation + 1) * (q.nodes[root].key + 1) + i64(q.nodes[root].item_id)
				if opcode == 3 { delete_min(mut q, root) }
			} else { return -1 }
		}
		return result
	}
}

@[export: 'skew_binomial_queue']
pub fn skew_binomial_queue(input &i64, length usize) i64 {
	return skew_binomial_queue_impl(input, length)
}
