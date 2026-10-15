package account_merge

import "core:c"

MAX_ACCOUNTS :: 64
MAX_EMAIL_REFERENCES :: 1024
EMAIL_TABLE_SIZE :: 2048

Email_Ref :: struct {
	start: int,
	length: int,
	account: int,
	root: int,
}

compare_text :: proc "contextless" (values: [^]i64, left_start, left_length, right_start, right_length: int) -> int {
	shared := left_length
	if right_length < shared do shared = right_length
	for i := 0; i < shared; i += 1 {
		if values[left_start+i] < values[right_start+i] do return -1
		if values[left_start+i] > values[right_start+i] do return 1
	}
	if left_length < right_length do return -1
	if left_length > right_length do return 1
	return 0
}

email_hash :: proc "contextless" (values: [^]i64, start, length: int) -> u64 {
	hash := u64(14695981039346656037)
	for i := 0; i < length; i += 1 {
		hash = (hash ^ u64(u8(values[start+i]))) * 1099511628211
	}
	return hash
}

find_root :: proc "contextless" (parent: ^[MAX_ACCOUNTS]int, value: int) -> int {
	root := value
	for parent[root] != root {
		parent[root] = parent[parent[root]]
		root = parent[root]
	}
	return root
}

join_accounts :: proc "contextless" (parent: ^[MAX_ACCOUNTS]int, rank: ^[MAX_ACCOUNTS]int, left, right: int) {
	left_root := find_root(parent, left)
	right_root := find_root(parent, right)
	if left_root == right_root do return
	if rank[left_root] < rank[right_root] {
		parent[left_root] = right_root
	} else if rank[left_root] > rank[right_root] {
		parent[right_root] = left_root
	} else {
		parent[right_root] = left_root
		rank[left_root] += 1
	}
}

sort_emails :: proc "contextless" (values: [^]i64, emails: ^[MAX_EMAIL_REFERENCES]Email_Ref, indices, scratch: ^[MAX_EMAIL_REFERENCES]int, count: int) {
	width := 1
	for width < count {
		low := 0
		for low < count {
			middle := low + width
			if middle > count do middle = count
			high := middle + width
			if high > count do high = count
			left, right, output := low, middle, low
			for left < middle && right < high {
				a := emails[indices[left]]
				b := emails[indices[right]]
				if compare_text(values, a.start, a.length, b.start, b.length) <= 0 {
					scratch[output] = indices[left]
					left += 1
				} else {
					scratch[output] = indices[right]
					right += 1
				}
				output += 1
			}
			for left < middle {
				scratch[output] = indices[left]
				left += 1; output += 1
			}
			for right < high {
				scratch[output] = indices[right]
				right += 1; output += 1
			}
			for i := low; i < high; i += 1 do indices[i] = scratch[i]
			low = high
		}
		if width > count / 2 do break
		width *= 2
	}
}

compare_groups :: proc "contextless" (values: [^]i64, name_start, name_length, email_count, first_email: ^[MAX_ACCOUNTS]int, emails: ^[MAX_EMAIL_REFERENCES]Email_Ref, left, right: int) -> int {
	comparison := compare_text(values, name_start[left], name_length[left], name_start[right], name_length[right])
	if comparison != 0 do return comparison
	if email_count[left] == 0 || email_count[right] == 0 {
		if email_count[left] != email_count[right] {
			if email_count[left] == 0 do return -1
			return 1
		}
		if left < right do return -1
		if left > right do return 1
		return 0
	}
	a := emails[first_email[left]]
	b := emails[first_email[right]]
	comparison = compare_text(values, a.start, a.length, b.start, b.length)
	if comparison != 0 do return comparison
	if left < right do return -1
	if left > right do return 1
	return 0
}

write_u16 :: proc "contextless" (output: [^]u8, position: ^int, value: int) {
	output[position^] = u8(value & 255)
	position^ += 1
	output[position^] = u8((value >> 8) & 255)
	position^ += 1
}

// Merge accounts sharing an email and encode the sorted groups as little-endian bytes.
@(export)
account_merge :: proc "c" (values: [^]i64, length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length == 0 do return -1
	if values[0] < 0 || values[0] > MAX_ACCOUNTS do return -1
	if length > 100002 do return -1
	input_length := int(length)
	account_count := int(values[0])
	name_start: [MAX_ACCOUNTS]int
	name_length: [MAX_ACCOUNTS]int
	parent: [MAX_ACCOUNTS]int
	rank: [MAX_ACCOUNTS]int
	emails: [MAX_EMAIL_REFERENCES]Email_Ref
	email_reference_count := 0
	table: [EMAIL_TABLE_SIZE]int
	for i := 0; i < EMAIL_TABLE_SIZE; i += 1 do table[i] = -1
	for i := 0; i < account_count; i += 1 do parent[i] = i
	position := 1
	for account := 0; account < account_count; account += 1 {
		if position >= input_length || values[position] < 1 || values[position] > 64 do return -1
		owner_length := int(values[position]); position += 1
		if owner_length > input_length - position do return -1
		name_start[account] = position; name_length[account] = owner_length
		for i := 0; i < owner_length; i += 1 {
			if values[position+i] < 32 || values[position+i] > 126 do return -1
		}
		position += owner_length
		if position >= input_length || values[position] < 0 || values[position] > MAX_EMAIL_REFERENCES do return -1
		account_email_count := int(values[position]); position += 1
		if account_email_count > MAX_EMAIL_REFERENCES - email_reference_count do return -1
		for _ in 0 ..< account_email_count {
			if position >= input_length || values[position] < 1 || values[position] > 64 do return -1
			email_length := int(values[position]); position += 1
			if email_length > input_length - position do return -1
			for i := 0; i < email_length; i += 1 {
				if values[position+i] < 33 || values[position+i] > 126 do return -1
			}
			emails[email_reference_count] = Email_Ref{position, email_length, account, 0}
			slot := int(email_hash(values, position, email_length) & u64(EMAIL_TABLE_SIZE - 1))
			for table[slot] >= 0 {
				previous := emails[table[slot]]
				if compare_text(values, position, email_length, previous.start, previous.length) == 0 {
					join_accounts(&parent, &rank, account, previous.account)
					break
				}
				slot = (slot + 1) & (EMAIL_TABLE_SIZE - 1)
			}
			if table[slot] < 0 do table[slot] = email_reference_count
			email_reference_count += 1; position += email_length
		}
	}
	if position != input_length do return -1

	group_roots: [MAX_ACCOUNTS]int
	group_count := 0
	root_seen: [MAX_ACCOUNTS]bool
	group_email_count: [MAX_ACCOUNTS]int
	first_email: [MAX_ACCOUNTS]int
	for account := 0; account < account_count; account += 1 {
		root := find_root(&parent, account)
		if compare_text(values, name_start[account], name_length[account], name_start[root], name_length[root]) != 0 do return -1
		if !root_seen[root] {
			root_seen[root] = true
			group_roots[group_count] = root
			group_count += 1
		}
	}
	unique_indices: [MAX_EMAIL_REFERENCES]int
	unique_count := 0
	for slot := 0; slot < EMAIL_TABLE_SIZE; slot += 1 {
		if table[slot] < 0 do continue
		index := table[slot]
		emails[index].root = find_root(&parent, emails[index].account)
		group_email_count[emails[index].root] += 1
		unique_indices[unique_count] = index; unique_count += 1
	}
	email_scratch: [MAX_EMAIL_REFERENCES]int
	sort_emails(values, &emails, &unique_indices, &email_scratch, unique_count)
	first_seen: [MAX_ACCOUNTS]bool
	for i := 0; i < unique_count; i += 1 {
		root := emails[unique_indices[i]].root
		if !first_seen[root] { first_seen[root] = true; first_email[root] = unique_indices[i] }
	}
	for i := 1; i < group_count; i += 1 {
		value := group_roots[i]
		destination := i
		for destination > 0 && compare_groups(values, &name_start, &name_length, &group_email_count, &first_email, &emails, value, group_roots[destination-1]) < 0 {
			group_roots[destination] = group_roots[destination-1]
			destination -= 1
		}
		group_roots[destination] = value
	}
	required := 2
	for g := 0; g < group_count; g += 1 {
		root := group_roots[g]
		required += 4 + name_length[root]
		for i := 0; i < unique_count; i += 1 {
			email := emails[unique_indices[i]]
			if email.root == root do required += 2 + email.length
		}
	}
	if output == nil || output_capacity < c.size_t(required) do return -2
	out_position := 0
	write_u16(output, &out_position, group_count)
	for g := 0; g < group_count; g += 1 {
		root := group_roots[g]
		write_u16(output, &out_position, name_length[root])
		write_u16(output, &out_position, group_email_count[root])
		for i := 0; i < name_length[root]; i += 1 {
			output[out_position] = u8(values[name_start[root]+i]); out_position += 1
		}
		for i := 0; i < unique_count; i += 1 {
			email := emails[unique_indices[i]]
			if email.root != root do continue
			write_u16(output, &out_position, email.length)
			for j := 0; j < email.length; j += 1 {
				output[out_position] = u8(values[email.start+j]); out_position += 1
			}
		}
	}
	return i64(out_position)
}
