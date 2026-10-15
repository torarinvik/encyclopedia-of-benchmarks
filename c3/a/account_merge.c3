module account_merge;

const usz MAX_ACCOUNTS = 64;
const usz MAX_EMAIL_REFERENCES = 1024;
const usz EMAIL_TABLE_SIZE = 2048;

fn usz find_root(usz* parent, usz value) {
    while (parent[value] != value) {
        parent[value] = parent[parent[value]];
        value = parent[value];
    }
    return value;
}

fn void join_accounts(usz* parent, usz* rank, usz left, usz right) {
    usz left_root = find_root(parent, left);
    usz right_root = find_root(parent, right);
    if (left_root == right_root) return;
    if (rank[left_root] < rank[right_root]) parent[left_root] = right_root;
    else if (rank[left_root] > rank[right_root]) parent[right_root] = left_root;
    else { parent[right_root] = left_root; rank[left_root]++; }
}

fn uint email_hash(long* values, usz start, usz length) {
    // Only the low 11 bits select a table bucket, so masking each step preserves the hash.
    uint hash = 805; // FNV offset basis modulo 2048.
    for (usz i = 0; i < length; i++) hash = ((hash ^ (uint)values[start + i]) * 435) & 2047;
    return hash;
}

fn int compare_text(long* values, usz left_start, usz left_length, usz right_start, usz right_length) {
    usz shared = left_length < right_length ? left_length : right_length;
    for (usz i = 0; i < shared; i++) {
        if (values[left_start + i] < values[right_start + i]) return -1;
        if (values[left_start + i] > values[right_start + i]) return 1;
    }
    if (left_length < right_length) return -1;
    if (left_length > right_length) return 1;
    return 0;
}

fn void sort_emails(long* values, usz* email_start, usz* email_length,
                    usz* indices, usz* scratch, usz count) {
    for (usz width = 1; width < count;) {
        usz low = 0;
        while (low < count) {
            usz middle = low + width;
            if (middle > count) middle = count;
            usz high = middle + width;
            if (high > count) high = count;
            usz left = low;
            usz right = middle;
            usz output = low;
            while (left < middle && right < high) {
                usz a = indices[left];
                usz b = indices[right];
                if (compare_text(values, email_start[a], email_length[a], email_start[b], email_length[b]) <= 0) {
                    scratch[output++] = indices[left++];
                } else {
                    scratch[output++] = indices[right++];
                }
            }
            while (left < middle) scratch[output++] = indices[left++];
            while (right < high) scratch[output++] = indices[right++];
            for (usz i = low; i < high; i++) indices[i] = scratch[i];
            low = high;
        }
        if (width > count / 2) break;
        width *= 2;
    }
}

fn int compare_groups(long* values, usz* name_start, usz* name_length,
                      usz* group_email_count, usz* first_email,
                      usz* email_start, usz* email_length, usz left, usz right) {
    int comparison = compare_text(values, name_start[left], name_length[left], name_start[right], name_length[right]);
    if (comparison != 0) return comparison;
    if (group_email_count[left] == 0 || group_email_count[right] == 0) {
        if (group_email_count[left] != group_email_count[right]) return group_email_count[left] == 0 ? -1 : 1;
        if (left < right) return -1;
        if (left > right) return 1;
        return 0;
    }
    usz a = first_email[left];
    usz b = first_email[right];
    comparison = compare_text(values, email_start[a], email_length[a], email_start[b], email_length[b]);
    if (comparison != 0) return comparison;
    if (left < right) return -1;
    if (left > right) return 1;
    return 0;
}

fn void write_u16(char* output, usz* position, usz value) {
    output[*position] = (char)(value & 255);
    *position = *position + 1;
    output[*position] = (char)((value >> 8) & 255);
    *position = *position + 1;
}

fn long account_merge(long* values, usz length, char* output, usz output_capacity)
    @export("account_merge") {
    if (values == null || length == 0 || values[0] < 0 || values[0] > MAX_ACCOUNTS) return -1;
    usz account_count = (usz)values[0];
    usz[MAX_ACCOUNTS] name_start;
    usz[MAX_ACCOUNTS] name_length;
    usz[MAX_ACCOUNTS] parent;
    usz[MAX_ACCOUNTS] rank = {0};
    usz[MAX_EMAIL_REFERENCES] email_start;
    usz[MAX_EMAIL_REFERENCES] email_length;
    usz[MAX_EMAIL_REFERENCES] email_account;
    usz[MAX_EMAIL_REFERENCES] email_root;
    int[EMAIL_TABLE_SIZE] table;
    for (usz i = 0; i < EMAIL_TABLE_SIZE; i++) table[i] = -1;
    for (usz i = 0; i < account_count; i++) parent[i] = i;
    usz email_reference_count = 0;
    usz position = 1;
    for (usz account = 0; account < account_count; account++) {
        if (position >= length || values[position] < 1 || values[position] > 64) return -1;
        usz owner_length = (usz)values[position++];
        if (owner_length > length - position) return -1;
        name_start[account] = position;
        name_length[account] = owner_length;
        for (usz byte = 0; byte < owner_length; byte++) {
            if (values[position + byte] < 32 || values[position + byte] > 126) return -1;
        }
        position += owner_length;
        if (position >= length || values[position] < 0 || values[position] > MAX_EMAIL_REFERENCES) return -1;
        usz account_email_count = (usz)values[position++];
        if (account_email_count > MAX_EMAIL_REFERENCES - email_reference_count) return -1;
        for (usz entry = 0; entry < account_email_count; entry++) {
            if (position >= length || values[position] < 1 || values[position] > 64) return -1;
            usz current_length = (usz)values[position++];
            if (current_length > length - position) return -1;
            for (usz byte = 0; byte < current_length; byte++) {
                if (values[position + byte] < 33 || values[position + byte] > 126) return -1;
            }
            email_start[email_reference_count] = position;
            email_length[email_reference_count] = current_length;
            email_account[email_reference_count] = account;
            uint slot = email_hash(values, position, current_length);
            while (table[slot] >= 0) {
                usz previous = (usz)table[slot];
                if (compare_text(values, position, current_length, email_start[previous], email_length[previous]) == 0) {
                    join_accounts(&parent[0], &rank[0], account, email_account[previous]);
                    break;
                }
                slot = (slot + 1) & (EMAIL_TABLE_SIZE - 1);
            }
            if (table[slot] < 0) table[slot] = (int)email_reference_count;
            email_reference_count++;
            position += current_length;
        }
    }
    if (position != length) return -1;

    usz[MAX_ACCOUNTS] group_roots;
    usz[MAX_ACCOUNTS] group_email_count = {0};
    usz[MAX_ACCOUNTS] first_email = {0};
    bool[MAX_ACCOUNTS] root_seen = {false};
    bool[MAX_ACCOUNTS] first_seen = {false};
    usz group_count = 0;
    for (usz account = 0; account < account_count; account++) {
        usz root = find_root(&parent[0], account);
        if (compare_text(values, name_start[account], name_length[account], name_start[root], name_length[root]) != 0) return -1;
        if (!root_seen[root]) { root_seen[root] = true; group_roots[group_count++] = root; }
    }
    usz[MAX_EMAIL_REFERENCES] unique_indices;
    usz[MAX_EMAIL_REFERENCES] scratch;
    usz unique_count = 0;
    for (usz slot = 0; slot < EMAIL_TABLE_SIZE; slot++) {
        if (table[slot] < 0) continue;
        usz index = (usz)table[slot];
        email_root[index] = find_root(&parent[0], email_account[index]);
        group_email_count[email_root[index]]++;
        unique_indices[unique_count++] = index;
    }
    sort_emails(values, &email_start[0], &email_length[0], &unique_indices[0], &scratch[0], unique_count);
    for (usz i = 0; i < unique_count; i++) {
        usz root = email_root[unique_indices[i]];
        if (!first_seen[root]) { first_seen[root] = true; first_email[root] = unique_indices[i]; }
    }
    for (usz i = 1; i < group_count; i++) {
        usz value = group_roots[i];
        usz destination = i;
        while (destination > 0 && compare_groups(values, &name_start[0], &name_length[0],
                &group_email_count[0], &first_email[0], &email_start[0], &email_length[0],
                value, group_roots[destination - 1]) < 0) {
            group_roots[destination] = group_roots[destination - 1];
            destination--;
        }
        group_roots[destination] = value;
    }
    usz required = 2;
    for (usz group = 0; group < group_count; group++) {
        usz root = group_roots[group];
        required += 4 + name_length[root];
        for (usz i = 0; i < unique_count; i++) {
            usz index = unique_indices[i];
            if (email_root[index] == root) required += 2 + email_length[index];
        }
    }
    if (output == null || output_capacity < required) return -2;
    usz output_position = 0;
    write_u16(output, &output_position, group_count);
    for (usz group = 0; group < group_count; group++) {
        usz root = group_roots[group];
        write_u16(output, &output_position, name_length[root]);
        write_u16(output, &output_position, group_email_count[root]);
        for (usz byte = 0; byte < name_length[root]; byte++) output[output_position++] = (char)values[name_start[root] + byte];
        for (usz i = 0; i < unique_count; i++) {
            usz index = unique_indices[i];
            if (email_root[index] != root) continue;
            write_u16(output, &output_position, email_length[index]);
            for (usz byte = 0; byte < email_length[index]; byte++) output[output_position++] = (char)values[email_start[index] + byte];
        }
    }
    return (long)output_position;
}
