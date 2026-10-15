module account_merge

const max_accounts = 64
const max_email_references = 1024
const email_table_size = 2048

struct EmailRef {
	start  usize
	length usize
	account usize
	root   usize
}

fn find_root(mut parent &usize, value usize) usize {
	mut node := value
	for unsafe { parent[node] != node } {
		unsafe { parent[node] = parent[parent[node]]; node = parent[node] }
	}
	return node
}

fn join_accounts(mut parent &usize, mut ranks &usize, left usize, right usize) {
	left_root := find_root(mut parent, left)
	right_root := find_root(mut parent, right)
	if left_root == right_root { return }
	if unsafe { ranks[left_root] < ranks[right_root] } {
		unsafe { parent[left_root] = right_root }
	} else if unsafe { ranks[left_root] > ranks[right_root] } {
		unsafe { parent[right_root] = left_root }
	} else {
		unsafe { parent[right_root] = left_root; ranks[left_root]++ }
	}
}

fn email_hash(values &i64, start usize, length usize) u64 {
	mut hash := u64(14695981039346656037)
	for index := usize(0); index < length; index++ {
		value := unsafe { u8(values[start + index]) }
		hash = (hash ^ u64(value)) * u64(1099511628211)
	}
	return hash
}

fn compare_text(values &i64, left_start usize, left_length usize, right_start usize, right_length usize) int {
	shared := if left_length < right_length { left_length } else { right_length }
	for index := usize(0); index < shared; index++ {
		left := unsafe { values[left_start + index] }
		right := unsafe { values[right_start + index] }
		if left < right { return -1 }
		if left > right { return 1 }
	}
	if left_length < right_length { return -1 }
	if left_length > right_length { return 1 }
	return 0
}

fn sort_emails(values &i64, emails &EmailRef, mut indices &usize, mut scratch &usize, count usize) {
	mut width := usize(1)
	for width < count {
		mut low := usize(0)
		for low < count {
			mut middle := low + width
			if middle > count { middle = count }
			mut high := middle + width
			if high > count { high = count }
			mut left := low
			mut right := middle
			mut output := low
			for left < middle && right < high {
				a := unsafe { emails[indices[left]] }
				b := unsafe { emails[indices[right]] }
				if compare_text(values, a.start, a.length, b.start, b.length) <= 0 {
					unsafe { scratch[output] = indices[left] }
					left++
				} else {
					unsafe { scratch[output] = indices[right] }
					right++
				}
				output++
			}
			for left < middle { unsafe { scratch[output] = indices[left] }; left++; output++ }
			for right < high { unsafe { scratch[output] = indices[right] }; right++; output++ }
			for index := low; index < high; index++ { unsafe { indices[index] = scratch[index] } }
			low = high
		}
		if width > count / 2 { break }
		width *= 2
	}
}

fn compare_groups(values &i64, name_start &usize, name_length &usize,
		email_count &usize, first_email &usize, emails &EmailRef, left usize, right usize) int {
	comparison := compare_text(values, unsafe { name_start[left] }, unsafe { name_length[left] },
		unsafe { name_start[right] }, unsafe { name_length[right] })
	if comparison != 0 { return comparison }
	left_count := unsafe { email_count[left] }
	right_count := unsafe { email_count[right] }
	if left_count == 0 || right_count == 0 {
		if left_count != right_count { return if left_count == 0 { -1 } else { 1 } }
		return if left < right { -1 } else if left > right { 1 } else { 0 }
	}
	a := unsafe { emails[first_email[left]] }
	b := unsafe { emails[first_email[right]] }
	comparison = compare_text(values, a.start, a.length, b.start, b.length)
	if comparison != 0 { return comparison }
	return if left < right { -1 } else if left > right { 1 } else { 0 }
}

fn write_u16(mut output &u8, mut position usize, value usize) {
	unsafe {
		output[position] = u8(value & 255)
		position++
		output[position] = u8((value >> 8) & 255)
		position++
	}
}

@[export: 'account_merge']
pub fn account_merge(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if values == nil || length == 0 { return -1 }
	unsafe {
		if values[0] < 0 || values[0] > max_accounts { return -1 }
		account_count := usize(values[0])
		mut name_start := [max_accounts]usize{}
		mut name_length := [max_accounts]usize{}
		mut parent := [max_accounts]usize{}
		mut ranks := [max_accounts]usize{}
		mut emails := [max_email_references]EmailRef{}
		mut table := [email_table_size]int{init: -1}
		for account := usize(0); account < account_count; account++ { parent[account] = account }
		mut email_reference_count := usize(0)
		mut position := usize(1)
		for account := usize(0); account < account_count; account++ {
			if position >= length || values[position] < 1 || values[position] > 64 { return -1 }
			owner_length := usize(values[position]); position++
			if owner_length > length - position { return -1 }
			name_start[account] = position
			name_length[account] = owner_length
			for byte := usize(0); byte < owner_length; byte++ {
				if values[position + byte] < 32 || values[position + byte] > 126 { return -1 }
			}
			position += owner_length
			if position >= length || values[position] < 0 || values[position] > max_email_references { return -1 }
			account_email_count := usize(values[position]); position++
			if account_email_count > max_email_references - email_reference_count { return -1 }
			for _ in 0 .. account_email_count {
				if position >= length || values[position] < 1 || values[position] > 64 { return -1 }
				email_length := usize(values[position]); position++
				if email_length > length - position { return -1 }
				for byte := usize(0); byte < email_length; byte++ {
					if values[position + byte] < 33 || values[position + byte] > 126 { return -1 }
				}
				emails[email_reference_count] = EmailRef{
					start: position
					length: email_length
					account: account
					root: 0
				}
				hash := email_hash(values, position, email_length)
				mut slot := usize(hash) & (email_table_size - 1)
				for table[slot] >= 0 {
					previous := emails[usize(table[slot])]
					if compare_text(values, position, email_length, previous.start, previous.length) == 0 {
						join_accounts(mut parent[0], mut ranks[0], account, previous.account)
						break
					}
					slot = (slot + 1) & (email_table_size - 1)
				}
				if table[slot] < 0 { table[slot] = int(email_reference_count) }
				email_reference_count++
				position += email_length
			}
		}
		if position != length { return -1 }

		mut group_roots := [max_accounts]usize{}
		mut group_count := usize(0)
		mut root_seen := [max_accounts]u8{}
		mut group_email_count := [max_accounts]usize{}
		mut first_email := [max_accounts]usize{}
		for account := usize(0); account < account_count; account++ {
			root := find_root(mut parent[0], account)
			if compare_text(values, name_start[account], name_length[account], name_start[root], name_length[root]) != 0 { return -1 }
			if root_seen[root] == 0 { root_seen[root] = 1; group_roots[group_count] = root; group_count++ }
		}

		mut unique_indices := [max_email_references]usize{}
		mut unique_count := usize(0)
		for slot := usize(0); slot < email_table_size; slot++ {
			if table[slot] < 0 { continue }
			index := usize(table[slot])
			emails[index].root = find_root(mut parent[0], emails[index].account)
			group_email_count[emails[index].root]++
			unique_indices[unique_count] = index
			unique_count++
		}
		mut email_scratch := [max_email_references]usize{}
		sort_emails(values, emails[0], mut unique_indices[0], mut email_scratch[0], unique_count)
		mut first_seen := [max_accounts]u8{}
		for index := usize(0); index < unique_count; index++ {
			root := emails[unique_indices[index]].root
			if first_seen[root] == 0 { first_seen[root] = 1; first_email[root] = unique_indices[index] }
		}
		for index := usize(1); index < group_count; index++ {
			value := group_roots[index]
			mut destination := index
			for destination > 0 && compare_groups(values, name_start[0], name_length[0], group_email_count[0], first_email[0], emails[0], value, group_roots[destination - 1]) < 0 {
				group_roots[destination] = group_roots[destination - 1]
				destination--
			}
			group_roots[destination] = value
		}

		mut required := usize(2)
		for group := usize(0); group < group_count; group++ {
			root := group_roots[group]
			required += 4 + name_length[root]
			for index := usize(0); index < unique_count; index++ {
				email := emails[unique_indices[index]]
				if email.root == root { required += 2 + email.length }
			}
		}
		if output == nil || output_capacity < required { return -2 }
		mut output_position := usize(0)
		write_u16(mut output, mut output_position, group_count)
		for group := usize(0); group < group_count; group++ {
			root := group_roots[group]
			write_u16(mut output, mut output_position, name_length[root])
			write_u16(mut output, mut output_position, group_email_count[root])
			for byte := usize(0); byte < name_length[root]; byte++ { output[output_position] = u8(values[name_start[root] + byte]); output_position++ }
			for index := usize(0); index < unique_count; index++ {
				email := emails[unique_indices[index]]
				if email.root != root { continue }
				write_u16(mut output, mut output_position, email.length)
				for byte := usize(0); byte < email.length; byte++ { output[output_position] = u8(values[email.start + byte]); output_position++ }
			}
		}
		return i64(output_position)
	}
}
