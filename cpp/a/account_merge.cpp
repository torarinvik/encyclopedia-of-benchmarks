// Merge accounts that share an email, then encode sorted groups as u16 little-endian bytes.
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_accounts = 64;
constexpr std::size_t max_email_references = 1024;
constexpr std::size_t email_table_size = 2048;

struct EmailRef { std::size_t start, length, account, root; };

std::size_t find_root(std::array<std::size_t, max_accounts>& parent, std::size_t value) noexcept {
    while (parent[value] != value) {
        parent[value] = parent[parent[value]];
        value = parent[value];
    }
    return value;
}

void join_accounts(std::array<std::size_t, max_accounts>& parent,
                   std::array<std::size_t, max_accounts>& rank,
                   std::size_t left, std::size_t right) noexcept {
    const auto left_root = find_root(parent, left);
    const auto right_root = find_root(parent, right);
    if (left_root == right_root) return;
    if (rank[left_root] < rank[right_root]) parent[left_root] = right_root;
    else if (rank[left_root] > rank[right_root]) parent[right_root] = left_root;
    else { parent[right_root] = left_root; ++rank[left_root]; }
}

int compare_text(const std::int64_t* values, std::size_t a, std::size_t al,
                 std::size_t b, std::size_t bl) noexcept {
    const auto shared = al < bl ? al : bl;
    for (std::size_t i = 0; i < shared; ++i) {
        if (values[a + i] < values[b + i]) return -1;
        if (values[a + i] > values[b + i]) return 1;
    }
    return (al > bl) - (al < bl);
}

std::uint64_t email_hash(const std::int64_t* values, std::size_t start,
                         std::size_t length) noexcept {
    std::uint64_t hash = UINT64_C(14695981039346656037);
    for (std::size_t i = 0; i < length; ++i)
        hash = (hash ^ static_cast<std::uint8_t>(values[start + i])) * UINT64_C(1099511628211);
    return hash;
}

void sort_emails(const std::int64_t* values, const std::array<EmailRef, max_email_references>& emails,
                 std::array<std::size_t, max_email_references>& indices,
                 std::array<std::size_t, max_email_references>& scratch,
                 std::size_t count) noexcept {
    for (std::size_t width = 1; width < count;) {
        std::size_t low = 0;
        while (low < count) {
            const auto middle = low + (width < count - low ? width : count - low);
            const auto high = middle + (width < count - middle ? width : count - middle);
            auto left = low, right = middle, out = low;
            while (left < middle && right < high) {
                const auto& a = emails[indices[left]];
                const auto& b = emails[indices[right]];
                if (compare_text(values, a.start, a.length, b.start, b.length) <= 0) scratch[out++] = indices[left++];
                else scratch[out++] = indices[right++];
            }
            while (left < middle) scratch[out++] = indices[left++];
            while (right < high) scratch[out++] = indices[right++];
            for (auto i = low; i < high; ++i) indices[i] = scratch[i];
            low = high;
        }
        if (width > count / 2) break;
        width *= 2;
    }
}

int compare_groups(const std::int64_t* values,
                   const std::array<std::size_t, max_accounts>& name_start,
                   const std::array<std::size_t, max_accounts>& name_length,
                   const std::array<std::size_t, max_accounts>& email_count,
                   const std::array<std::size_t, max_accounts>& first_email,
                   const std::array<EmailRef, max_email_references>& emails,
                   std::size_t left, std::size_t right) noexcept {
    auto comparison = compare_text(values, name_start[left], name_length[left], name_start[right], name_length[right]);
    if (comparison) return comparison;
    if (email_count[left] == 0 || email_count[right] == 0) {
        if (email_count[left] != email_count[right]) return email_count[left] == 0 ? -1 : 1;
        return (left > right) - (left < right);
    }
    const auto& a = emails[first_email[left]];
    const auto& b = emails[first_email[right]];
    comparison = compare_text(values, a.start, a.length, b.start, b.length);
    return comparison ? comparison : (left > right) - (left < right);
}

void write_u16(std::uint8_t* output, std::size_t& position, std::size_t value) noexcept {
    output[position++] = static_cast<std::uint8_t>(value & 255u);
    output[position++] = static_cast<std::uint8_t>((value >> 8) & 255u);
}
}

extern "C" std::int64_t account_merge(const std::int64_t* values, std::size_t length,
                                      std::uint8_t* output, std::size_t output_capacity) noexcept {
    if (values == nullptr || length == 0 || values[0] < 0 || values[0] > 64) return -1;
    const auto account_count = static_cast<std::size_t>(values[0]);
    std::array<std::size_t, max_accounts> name_start{}, name_length{}, parent{}, rank{};
    std::array<EmailRef, max_email_references> emails{};
    std::array<int, email_table_size> table{};
    table.fill(-1);
    for (std::size_t i = 0; i < account_count; ++i) parent[i] = i;
    std::size_t email_reference_count = 0, position = 1;
    for (std::size_t account = 0; account < account_count; ++account) {
        if (position >= length || values[position] < 1 || values[position] > 64) return -1;
        const auto owner_length = static_cast<std::size_t>(values[position++]);
        if (owner_length > length - position) return -1;
        name_start[account] = position; name_length[account] = owner_length;
        for (std::size_t b = 0; b < owner_length; ++b) if (values[position + b] < 32 || values[position + b] > 126) return -1;
        position += owner_length;
        if (position >= length || values[position] < 0 || values[position] > 1024) return -1;
        const auto count = static_cast<std::size_t>(values[position++]);
        if (count > max_email_references - email_reference_count) return -1;
        for (std::size_t entry = 0; entry < count; ++entry) {
            if (position >= length || values[position] < 1 || values[position] > 64) return -1;
            const auto email_length = static_cast<std::size_t>(values[position++]);
            if (email_length > length - position) return -1;
            for (std::size_t b = 0; b < email_length; ++b) if (values[position + b] < 33 || values[position + b] > 126) return -1;
            emails[email_reference_count] = {position, email_length, account, 0};
            auto slot = static_cast<std::size_t>(email_hash(values, position, email_length)) & (email_table_size - 1);
            while (table[slot] >= 0) {
                const auto& previous = emails[static_cast<std::size_t>(table[slot])];
                if (compare_text(values, position, email_length, previous.start, previous.length) == 0) {
                    join_accounts(parent, rank, account, previous.account); break;
                }
                slot = (slot + 1) & (email_table_size - 1);
            }
            if (table[slot] < 0) table[slot] = static_cast<int>(email_reference_count);
            ++email_reference_count; position += email_length;
        }
    }
    if (position != length) return -1;

    std::array<std::size_t, max_accounts> group_roots{}, group_email_count{}, first_email{};
    std::array<std::uint8_t, max_accounts> root_seen{}, first_seen{};
    std::size_t group_count = 0;
    for (std::size_t account = 0; account < account_count; ++account) {
        const auto root = find_root(parent, account);
        if (compare_text(values, name_start[account], name_length[account], name_start[root], name_length[root]) != 0) return -1;
        if (!root_seen[root]) { root_seen[root] = 1; group_roots[group_count++] = root; }
    }
    std::array<std::size_t, max_email_references> unique_indices{}, scratch{};
    std::size_t unique_count = 0;
    for (std::size_t slot = 0; slot < email_table_size; ++slot) if (table[slot] >= 0) {
        const auto index = static_cast<std::size_t>(table[slot]);
        emails[index].root = find_root(parent, emails[index].account);
        ++group_email_count[emails[index].root]; unique_indices[unique_count++] = index;
    }
    sort_emails(values, emails, unique_indices, scratch, unique_count);
    for (std::size_t i = 0; i < unique_count; ++i) {
        const auto root = emails[unique_indices[i]].root;
        if (!first_seen[root]) { first_seen[root] = 1; first_email[root] = unique_indices[i]; }
    }
    for (std::size_t i = 1; i < group_count; ++i) {
        const auto value = group_roots[i]; auto dest = i;
        while (dest > 0 && compare_groups(values, name_start, name_length, group_email_count,
                                         first_email, emails, value, group_roots[dest - 1]) < 0) {
            group_roots[dest] = group_roots[dest - 1]; --dest;
        }
        group_roots[dest] = value;
    }
    std::size_t required = 2;
    for (std::size_t g = 0; g < group_count; ++g) {
        const auto root = group_roots[g]; required += 4 + name_length[root];
        for (std::size_t i = 0; i < unique_count; ++i) if (emails[unique_indices[i]].root == root) required += 2 + emails[unique_indices[i]].length;
    }
    if (output == nullptr || output_capacity < required) return -2;
    std::size_t out = 0; write_u16(output, out, group_count);
    for (std::size_t g = 0; g < group_count; ++g) {
        const auto root = group_roots[g]; write_u16(output, out, name_length[root]); write_u16(output, out, group_email_count[root]);
        for (std::size_t b = 0; b < name_length[root]; ++b) output[out++] = static_cast<std::uint8_t>(values[name_start[root] + b]);
        for (std::size_t i = 0; i < unique_count; ++i) {
            const auto& email = emails[unique_indices[i]]; if (email.root != root) continue;
            write_u16(output, out, email.length);
            for (std::size_t b = 0; b < email.length; ++b) output[out++] = static_cast<std::uint8_t>(values[email.start + b]);
        }
    }
    return static_cast<std::int64_t>(out);
}
