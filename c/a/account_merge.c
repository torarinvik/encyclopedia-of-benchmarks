#include <stddef.h>
#include <stdint.h>

#define MAX_ACCOUNTS 64
#define MAX_EMAIL_REFERENCES 1024
#define EMAIL_TABLE_SIZE 2048

typedef struct {
    size_t start;
    size_t length;
    size_t account;
    size_t root;
} email_ref;

static size_t find_root(size_t *parent, size_t value)
{
    while (parent[value] != value) {
        parent[value] = parent[parent[value]];
        value = parent[value];
    }
    return value;
}

static void join_accounts(size_t *parent, size_t *rank, size_t left, size_t right)
{
    size_t left_root = find_root(parent, left);
    size_t right_root = find_root(parent, right);
    if (left_root == right_root) return;
    if (rank[left_root] < rank[right_root]) {
        parent[left_root] = right_root;
    } else if (rank[left_root] > rank[right_root]) {
        parent[right_root] = left_root;
    } else {
        parent[right_root] = left_root;
        rank[left_root]++;
    }
}

static uint64_t email_hash(const int64_t *values, size_t start, size_t length)
{
    uint64_t hash = UINT64_C(14695981039346656037);
    for (size_t index = 0; index < length; ++index)
        hash = (hash ^ (uint8_t)values[start + index]) * UINT64_C(1099511628211);
    return hash;
}

static int compare_text(const int64_t *values, size_t left_start, size_t left_length,
                        size_t right_start, size_t right_length)
{
    const size_t shared = left_length < right_length ? left_length : right_length;
    for (size_t index = 0; index < shared; ++index) {
        const int64_t left = values[left_start + index];
        const int64_t right = values[right_start + index];
        if (left < right) return -1;
        if (left > right) return 1;
    }
    return (left_length > right_length) - (left_length < right_length);
}

static int same_text(const int64_t *values, size_t left_start, size_t left_length,
                     size_t right_start, size_t right_length)
{
    return compare_text(values, left_start, left_length, right_start, right_length) == 0;
}

static void sort_emails(const int64_t *values, const email_ref *emails,
                        size_t *indices, size_t *scratch, size_t count)
{
    for (size_t width = 1; width < count;) {
        size_t low = 0;
        while (low < count) {
            size_t middle = low + width;
            if (middle > count) middle = count;
            size_t high = middle + width;
            if (high > count) high = count;
            size_t left = low, right = middle, output = low;
            while (left < middle && right < high) {
                const email_ref *a = &emails[indices[left]];
                const email_ref *b = &emails[indices[right]];
                if (compare_text(values, a->start, a->length, b->start, b->length) <= 0)
                    scratch[output++] = indices[left++];
                else
                    scratch[output++] = indices[right++];
            }
            while (left < middle) scratch[output++] = indices[left++];
            while (right < high) scratch[output++] = indices[right++];
            for (size_t index = low; index < high; ++index) indices[index] = scratch[index];
            low = high;
        }
        if (width > count / 2) break;
        width *= 2;
    }
}

static int compare_groups(const int64_t *values, const size_t *name_start,
                          const size_t *name_length, const size_t *email_count,
                          const size_t *first_email, const email_ref *emails,
                          size_t left, size_t right)
{
    int comparison = compare_text(values, name_start[left], name_length[left],
                                  name_start[right], name_length[right]);
    if (comparison != 0) return comparison;
    if (email_count[left] == 0 || email_count[right] == 0) {
        if (email_count[left] != email_count[right])
            return email_count[left] == 0 ? -1 : 1;
        return (left > right) - (left < right);
    }
    const email_ref *left_first = &emails[first_email[left]];
    const email_ref *right_first = &emails[first_email[right]];
    comparison = compare_text(values, left_first->start, left_first->length,
                              right_first->start, right_first->length);
    if (comparison != 0) return comparison;
    return (left > right) - (left < right);
}

static void write_u16(uint8_t *output, size_t *position, size_t value)
{
    output[(*position)++] = (uint8_t)(value & 255u);
    output[(*position)++] = (uint8_t)((value >> 8) & 255u);
}

int64_t account_merge(const int64_t *values, size_t length,
                      uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length == 0) return -1;
    if (values[0] < 0 || values[0] > MAX_ACCOUNTS) return -1;
    const size_t account_count = (size_t)values[0];
    size_t name_start[MAX_ACCOUNTS], name_length[MAX_ACCOUNTS];
    size_t parent[MAX_ACCOUNTS], rank[MAX_ACCOUNTS] = {0};
    email_ref emails[MAX_EMAIL_REFERENCES];
    size_t email_reference_count = 0;
    int table[EMAIL_TABLE_SIZE];
    for (size_t index = 0; index < EMAIL_TABLE_SIZE; ++index) table[index] = -1;
    for (size_t index = 0; index < account_count; ++index) parent[index] = index;

    size_t position = 1;
    for (size_t account = 0; account < account_count; ++account) {
        if (position >= length || values[position] < 1 || values[position] > 64) return -1;
        const size_t owner_length = (size_t)values[position++];
        if (owner_length > length - position) return -1;
        name_start[account] = position;
        name_length[account] = owner_length;
        for (size_t byte = 0; byte < owner_length; ++byte)
            if (values[position + byte] < 32 || values[position + byte] > 126) return -1;
        position += owner_length;
        if (position >= length || values[position] < 0 ||
            values[position] > MAX_EMAIL_REFERENCES) return -1;
        const size_t account_email_count = (size_t)values[position++];
        if (account_email_count > MAX_EMAIL_REFERENCES - email_reference_count) return -1;
        for (size_t entry = 0; entry < account_email_count; ++entry) {
            if (position >= length || values[position] < 1 || values[position] > 64) return -1;
            const size_t email_length = (size_t)values[position++];
            if (email_length > length - position) return -1;
            for (size_t byte = 0; byte < email_length; ++byte)
                if (values[position + byte] < 33 || values[position + byte] > 126) return -1;
            emails[email_reference_count] = (email_ref){position, email_length, account, 0};
            const uint64_t hash = email_hash(values, position, email_length);
            size_t slot = (size_t)hash & (EMAIL_TABLE_SIZE - 1);
            while (table[slot] >= 0) {
                const email_ref *previous = &emails[(size_t)table[slot]];
                if (same_text(values, position, email_length, previous->start, previous->length)) {
                    join_accounts(parent, rank, account, previous->account);
                    break;
                }
                slot = (slot + 1) & (EMAIL_TABLE_SIZE - 1);
            }
            if (table[slot] < 0) table[slot] = (int)email_reference_count;
            ++email_reference_count;
            position += email_length;
        }
    }
    if (position != length) return -1;

    size_t group_roots[MAX_ACCOUNTS], group_count = 0;
    uint8_t root_seen[MAX_ACCOUNTS] = {0};
    size_t group_email_count[MAX_ACCOUNTS] = {0};
    size_t first_email[MAX_ACCOUNTS] = {0};
    for (size_t account = 0; account < account_count; ++account) {
        const size_t root = find_root(parent, account);
        if (!same_text(values, name_start[account], name_length[account],
                       name_start[root], name_length[root])) return -1;
        if (!root_seen[root]) {
            root_seen[root] = 1;
            group_roots[group_count++] = root;
        }
    }

    size_t unique_indices[MAX_EMAIL_REFERENCES], unique_count = 0;
    for (size_t slot = 0; slot < EMAIL_TABLE_SIZE; ++slot) {
        if (table[slot] < 0) continue;
        const size_t index = (size_t)table[slot];
        emails[index].root = find_root(parent, emails[index].account);
        ++group_email_count[emails[index].root];
        unique_indices[unique_count++] = index;
    }
    size_t email_scratch[MAX_EMAIL_REFERENCES];
    sort_emails(values, emails, unique_indices, email_scratch, unique_count);
    uint8_t first_seen[MAX_ACCOUNTS] = {0};
    for (size_t index = 0; index < unique_count; ++index) {
        const size_t root = emails[unique_indices[index]].root;
        if (!first_seen[root]) {
            first_seen[root] = 1;
            first_email[root] = unique_indices[index];
        }
    }

    for (size_t index = 1; index < group_count; ++index) {
        const size_t value = group_roots[index];
        size_t destination = index;
        while (destination > 0 && compare_groups(values, name_start, name_length,
               group_email_count, first_email, emails, value, group_roots[destination - 1]) < 0) {
            group_roots[destination] = group_roots[destination - 1];
            --destination;
        }
        group_roots[destination] = value;
    }

    size_t required = 2;
    for (size_t group = 0; group < group_count; ++group) {
        const size_t root = group_roots[group];
        required += 4 + name_length[root];
        for (size_t index = 0; index < unique_count; ++index) {
            const email_ref *email = &emails[unique_indices[index]];
            if (email->root == root) required += 2 + email->length;
        }
    }
    if (output == NULL || output_capacity < required) return -2;

    size_t output_position = 0;
    write_u16(output, &output_position, group_count);
    for (size_t group = 0; group < group_count; ++group) {
        const size_t root = group_roots[group];
        write_u16(output, &output_position, name_length[root]);
        write_u16(output, &output_position, group_email_count[root]);
        for (size_t byte = 0; byte < name_length[root]; ++byte)
            output[output_position++] = (uint8_t)values[name_start[root] + byte];
        for (size_t index = 0; index < unique_count; ++index) {
            const email_ref *email = &emails[unique_indices[index]];
            if (email->root != root) continue;
            write_u16(output, &output_position, email->length);
            for (size_t byte = 0; byte < email->length; ++byte)
                output[output_position++] = (uint8_t)values[email->start + byte];
        }
    }
    return (int64_t)output_position;
}
