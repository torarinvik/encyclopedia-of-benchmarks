const MAX_ACCOUNTS: usize = 64;
const MAX_EMAIL_REFERENCES: usize = 1024;
const EMAIL_TABLE_SIZE: usize = 2048;

#[derive(Clone, Copy, Default)]
struct EmailRef {
    start: usize,
    length: usize,
    account: usize,
    root: usize,
}

unsafe fn byte(values: *const i64, index: usize) -> i64 {
    *values.add(index)
}

unsafe fn compare_text(values: *const i64, ls: usize, ll: usize, rs: usize, rl: usize) -> i32 {
    for offset in 0..ll.min(rl) {
        let left = byte(values, ls + offset);
        let right = byte(values, rs + offset);
        if left < right { return -1; }
        if left > right { return 1; }
    }
    match ll.cmp(&rl) { std::cmp::Ordering::Less => -1, std::cmp::Ordering::Greater => 1, _ => 0 }
}

unsafe fn email_hash(values: *const i64, start: usize, length: usize) -> u64 {
    let mut hash = 14695981039346656037u64;
    for offset in 0..length {
        hash = (hash ^ (byte(values, start + offset) as u8 as u64)).wrapping_mul(1099511628211);
    }
    hash
}

fn find_root(parent: &mut [usize; MAX_ACCOUNTS], mut value: usize) -> usize {
    while parent[value] != value {
        parent[value] = parent[parent[value]];
        value = parent[value];
    }
    value
}

fn join_accounts(parent: &mut [usize; MAX_ACCOUNTS], rank: &mut [usize; MAX_ACCOUNTS], left: usize, right: usize) {
    let left_root = find_root(parent, left);
    let right_root = find_root(parent, right);
    if left_root == right_root { return; }
    if rank[left_root] < rank[right_root] {
        parent[left_root] = right_root;
    } else if rank[left_root] > rank[right_root] {
        parent[right_root] = left_root;
    } else {
        parent[right_root] = left_root;
        rank[left_root] += 1;
    }
}

unsafe fn sort_emails(values: *const i64, emails: &[EmailRef; MAX_EMAIL_REFERENCES], indices: &mut [usize; MAX_EMAIL_REFERENCES], scratch: &mut [usize; MAX_EMAIL_REFERENCES], count: usize) {
    let mut width = 1;
    while width < count {
        let mut low = 0;
        while low < count {
            let middle = (low + width).min(count);
            let high = (middle + width).min(count);
            let (mut left, mut right, mut output) = (low, middle, low);
            while left < middle && right < high {
                let a = emails[indices[left]];
                let b = emails[indices[right]];
                if compare_text(values, a.start, a.length, b.start, b.length) <= 0 {
                    scratch[output] = indices[left]; left += 1;
                } else {
                    scratch[output] = indices[right]; right += 1;
                }
                output += 1;
            }
            while left < middle { scratch[output] = indices[left]; left += 1; output += 1; }
            while right < high { scratch[output] = indices[right]; right += 1; output += 1; }
            indices[low..high].copy_from_slice(&scratch[low..high]);
            low = high;
        }
        if width > count / 2 { break; }
        width *= 2;
    }
}

unsafe fn compare_groups(values: *const i64, name_start: &[usize; MAX_ACCOUNTS], name_length: &[usize; MAX_ACCOUNTS], email_count: &[usize; MAX_ACCOUNTS], first_email: &[usize; MAX_ACCOUNTS], emails: &[EmailRef; MAX_EMAIL_REFERENCES], left: usize, right: usize) -> i32 {
    let comparison = compare_text(values, name_start[left], name_length[left], name_start[right], name_length[right]);
    if comparison != 0 { return comparison; }
    if email_count[left] == 0 || email_count[right] == 0 {
        if email_count[left] != email_count[right] { return if email_count[left] == 0 { -1 } else { 1 }; }
        return if left < right { -1 } else if left > right { 1 } else { 0 };
    }
    let a = emails[first_email[left]];
    let b = emails[first_email[right]];
    let comparison = compare_text(values, a.start, a.length, b.start, b.length);
    if comparison != 0 { comparison } else if left < right { -1 } else if left > right { 1 } else { 0 }
}

unsafe fn write_u16(output: *mut u8, position: &mut usize, value: usize) {
    output.add(*position).write((value & 255) as u8); *position += 1;
    output.add(*position).write(((value >> 8) & 255) as u8); *position += 1;
}

/// Merge accounts sharing an email and encode the sorted groups as little-endian bytes.
#[no_mangle]
pub unsafe extern "C" fn account_merge(values: *const i64, length: usize, output: *mut u8, output_capacity: usize) -> i64 {
    if values.is_null() || length == 0 || byte(values, 0) < 0 || byte(values, 0) > MAX_ACCOUNTS as i64 { return -1; }
    let account_count = byte(values, 0) as usize;
    let mut name_start = [0usize; MAX_ACCOUNTS];
    let mut name_length = [0usize; MAX_ACCOUNTS];
    let mut parent = [0usize; MAX_ACCOUNTS];
    let mut rank = [0usize; MAX_ACCOUNTS];
    let mut emails = [EmailRef::default(); MAX_EMAIL_REFERENCES];
    let mut email_reference_count = 0;
    let mut table = [-1i32; EMAIL_TABLE_SIZE];
    for i in 0..account_count { parent[i] = i; }
    let mut position = 1usize;
    for account in 0..account_count {
        if position >= length { return -1; }
        let n = byte(values, position);
        if !(1..=64).contains(&n) { return -1; }
        position += 1;
        let n = n as usize;
        if n > length - position { return -1; }
        name_start[account] = position; name_length[account] = n;
        for j in 0..n { let c = byte(values, position + j); if !(32..=126).contains(&c) { return -1; } }
        position += n;
        if position >= length { return -1; }
        let count = byte(values, position);
        if count < 0 || count > MAX_EMAIL_REFERENCES as i64 { return -1; }
        position += 1;
        let count = count as usize;
        if count > MAX_EMAIL_REFERENCES - email_reference_count { return -1; }
        for _ in 0..count {
            if position >= length { return -1; }
            let elen = byte(values, position);
            if !(1..=64).contains(&elen) { return -1; }
            position += 1; let elen = elen as usize;
            if elen > length - position { return -1; }
            for j in 0..elen { let c = byte(values, position + j); if !(33..=126).contains(&c) { return -1; } }
            emails[email_reference_count] = EmailRef { start: position, length: elen, account, root: 0 };
            let hash = email_hash(values, position, elen);
            let mut slot = hash as usize & (EMAIL_TABLE_SIZE - 1);
            while table[slot] >= 0 {
                let previous = emails[table[slot] as usize];
                if compare_text(values, position, elen, previous.start, previous.length) == 0 {
                    join_accounts(&mut parent, &mut rank, account, previous.account); break;
                }
                slot = (slot + 1) & (EMAIL_TABLE_SIZE - 1);
            }
            if table[slot] < 0 { table[slot] = email_reference_count as i32; }
            email_reference_count += 1; position += elen;
        }
    }
    if position != length { return -1; }
    let mut group_roots = [0usize; MAX_ACCOUNTS];
    let mut group_count = 0;
    let mut root_seen = [false; MAX_ACCOUNTS];
    let mut group_email_count = [0usize; MAX_ACCOUNTS];
    let mut first_email = [0usize; MAX_ACCOUNTS];
    for account in 0..account_count {
        let root = find_root(&mut parent, account);
        if compare_text(values, name_start[account], name_length[account], name_start[root], name_length[root]) != 0 { return -1; }
        if !root_seen[root] { root_seen[root] = true; group_roots[group_count] = root; group_count += 1; }
    }
    let mut unique_indices = [0usize; MAX_EMAIL_REFERENCES]; let mut unique_count = 0;
    for entry in table.iter() {
        if *entry < 0 { continue; }
        let index = *entry as usize;
        emails[index].root = find_root(&mut parent, emails[index].account);
        group_email_count[emails[index].root] += 1;
        unique_indices[unique_count] = index; unique_count += 1;
    }
    let mut scratch = [0usize; MAX_EMAIL_REFERENCES];
    sort_emails(values, &emails, &mut unique_indices, &mut scratch, unique_count);
    let mut first_seen = [false; MAX_ACCOUNTS];
    for &index in unique_indices[..unique_count].iter() {
        let root = emails[index].root;
        if !first_seen[root] { first_seen[root] = true; first_email[root] = index; }
    }
    for i in 1..group_count {
        let value = group_roots[i]; let mut destination = i;
        while destination > 0 && compare_groups(values, &name_start, &name_length, &group_email_count, &first_email, &emails, value, group_roots[destination - 1]) < 0 {
            group_roots[destination] = group_roots[destination - 1]; destination -= 1;
        }
        group_roots[destination] = value;
    }
    let mut required = 2usize;
    for &root in group_roots[..group_count].iter() {
        required += 4 + name_length[root];
        for &index in unique_indices[..unique_count].iter() { let email = emails[index]; if email.root == root { required += 2 + email.length; } }
    }
    if output.is_null() || output_capacity < required { return -2; }
    let mut out = 0usize; write_u16(output, &mut out, group_count);
    for &root in group_roots[..group_count].iter() {
        write_u16(output, &mut out, name_length[root]); write_u16(output, &mut out, group_email_count[root]);
        for j in 0..name_length[root] { output.add(out).write(byte(values, name_start[root] + j) as u8); out += 1; }
        for &index in unique_indices[..unique_count].iter() {
            let email = emails[index]; if email.root != root { continue; }
            write_u16(output, &mut out, email.length);
            for j in 0..email.length { output.add(out).write(byte(values, email.start + j) as u8); out += 1; }
        }
    }
    out as i64
}
