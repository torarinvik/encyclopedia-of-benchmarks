const MAX_ACCOUNTS: usize = 64;
const MAX_EMAIL_REFERENCES: usize = 1024;
const EMAIL_TABLE_SIZE: usize = 2048;

const EmailRef = struct {
    start: usize,
    length: usize,
    account: usize,
    root: usize,
};

fn findRoot(parent: []usize, value: usize) usize {
    var node = value;
    while (parent[node] != node) {
        parent[node] = parent[parent[node]];
        node = parent[node];
    }
    return node;
}

fn joinAccounts(parent: []usize, ranks: []usize, left: usize, right: usize) void {
    const left_root = findRoot(parent, left);
    const right_root = findRoot(parent, right);
    if (left_root == right_root) return;
    if (ranks[left_root] < ranks[right_root]) {
        parent[left_root] = right_root;
    } else if (ranks[left_root] > ranks[right_root]) {
        parent[right_root] = left_root;
    } else {
        parent[right_root] = left_root;
        ranks[left_root] += 1;
    }
}

fn emailHash(values: [*c]const i64, start: usize, length: usize) u64 {
    var hash: u64 = 14695981039346656037;
    for (0..length) |index| {
        hash = (hash ^ @as(u8, @intCast(values[start + index]))) *% 1099511628211;
    }
    return hash;
}

fn compareText(values: [*c]const i64, left_start: usize, left_length: usize,
    right_start: usize, right_length: usize) i32 {
    const shared = @min(left_length, right_length);
    for (0..shared) |index| {
        const left = values[left_start + index];
        const right = values[right_start + index];
        if (left < right) return -1;
        if (left > right) return 1;
    }
    if (left_length < right_length) return -1;
    if (left_length > right_length) return 1;
    return 0;
}

fn sortEmails(values: [*c]const i64, emails: []const EmailRef,
    indices: []usize, scratch: []usize, count: usize) void {
    var width: usize = 1;
    while (width < count) {
        var low: usize = 0;
        while (low < count) {
            const middle = @min(low + width, count);
            const high = @min(middle + width, count);
            var left = low;
            var right = middle;
            var output = low;
            while (left < middle and right < high) {
                const a = emails[indices[left]];
                const b = emails[indices[right]];
                if (compareText(values, a.start, a.length, b.start, b.length) <= 0) {
                    scratch[output] = indices[left];
                    left += 1;
                } else {
                    scratch[output] = indices[right];
                    right += 1;
                }
                output += 1;
            }
            while (left < middle) : (left += 1) {
                scratch[output] = indices[left];
                output += 1;
            }
            while (right < high) : (right += 1) {
                scratch[output] = indices[right];
                output += 1;
            }
            for (low..high) |index| indices[index] = scratch[index];
            low = high;
        }
        if (width > count / 2) break;
        width *= 2;
    }
}

fn compareGroups(values: [*c]const i64, name_start: []const usize,
    name_length: []const usize, email_count: []const usize,
    first_email: []const usize, emails: []const EmailRef,
    left: usize, right: usize) i32 {
    var comparison = compareText(values, name_start[left], name_length[left],
        name_start[right], name_length[right]);
    if (comparison != 0) return comparison;
    if (email_count[left] == 0 or email_count[right] == 0) {
        if (email_count[left] != email_count[right]) return if (email_count[left] == 0) -1 else 1;
        if (left < right) return -1;
        if (left > right) return 1;
        return 0;
    }
    const a = emails[first_email[left]];
    const b = emails[first_email[right]];
    comparison = compareText(values, a.start, a.length, b.start, b.length);
    if (comparison != 0) return comparison;
    if (left < right) return -1;
    if (left > right) return 1;
    return 0;
}

fn writeU16(output: [*c]u8, position: *usize, value: usize) void {
    output[position.*] = @truncate(value & 255);
    position.* += 1;
    output[position.*] = @truncate((value >> 8) & 255);
    position.* += 1;
}

/// Merge accounts sharing any email address and encode the sorted groups.
export fn account_merge(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length == 0) return -1;
    if (values[0] < 0 or values[0] > MAX_ACCOUNTS) return -1;
    const account_count: usize = @intCast(values[0]);
    var name_start: [MAX_ACCOUNTS]usize = undefined;
    var name_length: [MAX_ACCOUNTS]usize = undefined;
    var parent: [MAX_ACCOUNTS]usize = undefined;
    var ranks: [MAX_ACCOUNTS]usize = @splat(0);
    var emails: [MAX_EMAIL_REFERENCES]EmailRef = undefined;
    var table: [EMAIL_TABLE_SIZE]i32 = @splat(-1);
    for (0..account_count) |account| parent[account] = account;

    var email_reference_count: usize = 0;
    var position: usize = 1;
    for (0..account_count) |account| {
        if (position >= length or values[position] < 1 or values[position] > 64) return -1;
        const owner_length: usize = @intCast(values[position]);
        position += 1;
        if (owner_length > length - position) return -1;
        name_start[account] = position;
        name_length[account] = owner_length;
        for (0..owner_length) |byte| {
            if (values[position + byte] < 32 or values[position + byte] > 126) return -1;
        }
        position += owner_length;
        if (position >= length or values[position] < 0 or values[position] > MAX_EMAIL_REFERENCES) return -1;
        const account_email_count: usize = @intCast(values[position]);
        position += 1;
        if (account_email_count > MAX_EMAIL_REFERENCES - email_reference_count) return -1;
        for (0..account_email_count) |_| {
            if (position >= length or values[position] < 1 or values[position] > 64) return -1;
            const email_length: usize = @intCast(values[position]);
            position += 1;
            if (email_length > length - position) return -1;
            for (0..email_length) |byte| {
                if (values[position + byte] < 33 or values[position + byte] > 126) return -1;
            }
            emails[email_reference_count] = .{
                .start = position,
                .length = email_length,
                .account = account,
                .root = 0,
            };
            const hash = emailHash(values, position, email_length);
            var slot: usize = @intCast(hash & (EMAIL_TABLE_SIZE - 1));
            while (table[slot] >= 0) {
                const previous = emails[@intCast(table[slot])];
                if (compareText(values, position, email_length, previous.start, previous.length) == 0) {
                    joinAccounts(parent[0..], ranks[0..], account, previous.account);
                    break;
                }
                slot = (slot + 1) & (EMAIL_TABLE_SIZE - 1);
            }
            if (table[slot] < 0) table[slot] = @intCast(email_reference_count);
            email_reference_count += 1;
            position += email_length;
        }
    }
    if (position != length) return -1;

    var group_roots: [MAX_ACCOUNTS]usize = undefined;
    var group_count: usize = 0;
    var root_seen: [MAX_ACCOUNTS]bool = @splat(false);
    var group_email_count: [MAX_ACCOUNTS]usize = @splat(0);
    var first_email: [MAX_ACCOUNTS]usize = @splat(0);
    for (0..account_count) |account| {
        const root = findRoot(parent[0..], account);
        if (compareText(values, name_start[account], name_length[account], name_start[root], name_length[root]) != 0) return -1;
        if (!root_seen[root]) {
            root_seen[root] = true;
            group_roots[group_count] = root;
            group_count += 1;
        }
    }

    var unique_indices: [MAX_EMAIL_REFERENCES]usize = undefined;
    var unique_count: usize = 0;
    for (0..EMAIL_TABLE_SIZE) |slot| {
        if (table[slot] < 0) continue;
        const index: usize = @intCast(table[slot]);
        emails[index].root = findRoot(parent[0..], emails[index].account);
        group_email_count[emails[index].root] += 1;
        unique_indices[unique_count] = index;
        unique_count += 1;
    }
    var email_scratch: [MAX_EMAIL_REFERENCES]usize = undefined;
    sortEmails(values, emails[0..], unique_indices[0..], email_scratch[0..], unique_count);
    var first_seen: [MAX_ACCOUNTS]bool = @splat(false);
    for (0..unique_count) |index| {
        const root = emails[unique_indices[index]].root;
        if (!first_seen[root]) {
            first_seen[root] = true;
            first_email[root] = unique_indices[index];
        }
    }
    var group_index: usize = 1;
    while (group_index < group_count) : (group_index += 1) {
        const index = group_index;
        const value = group_roots[index];
        var destination = index;
        while (destination > 0 and compareGroups(values, name_start[0..], name_length[0..],
            group_email_count[0..], first_email[0..], emails[0..], value,
            group_roots[destination - 1]) < 0) {
            group_roots[destination] = group_roots[destination - 1];
            destination -= 1;
        }
        group_roots[destination] = value;
    }

    var required: usize = 2;
    for (0..group_count) |group| {
        const root = group_roots[group];
        required += 4 + name_length[root];
        for (0..unique_count) |index| {
            const email = emails[unique_indices[index]];
            if (email.root == root) required += 2 + email.length;
        }
    }
    if (output == null or output_capacity < required) return -2;
    var output_position: usize = 0;
    writeU16(output, &output_position, group_count);
    for (0..group_count) |group| {
        const root = group_roots[group];
        writeU16(output, &output_position, name_length[root]);
        writeU16(output, &output_position, group_email_count[root]);
        for (0..name_length[root]) |byte| {
            output[output_position] = @intCast(values[name_start[root] + byte]);
            output_position += 1;
        }
        for (0..unique_count) |index| {
            const email = emails[unique_indices[index]];
            if (email.root != root) continue;
            writeU16(output, &output_position, email.length);
            for (0..email.length) |byte| {
                output[output_position] = @intCast(values[email.start + byte]);
                output_position += 1;
            }
        }
    }
    return @intCast(output_position);
}
