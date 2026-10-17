const MAX_N: usize = 256;
const MAX_MERGES: usize = 512;
const MAX_VALID_INPUT_LENGTH: usize = 1027;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 1028;

fn findRoot(parent: *const [MAX_N]usize, element_arg: usize) usize {
    var element = element_arg;
    while (parent[element] != element) element = parent[element];
    return element;
}

export fn merge_find_set(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 3 or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > @as(i64, @intCast(MAX_N)) or input[1] < 0 or input[1] > @as(i64, @intCast(MAX_MERGES))) return -1;
    const n: usize = @intCast(input[0]);
    const merge_count: usize = @intCast(input[1]);
    if (length != 2 * merge_count + 3 or length > MAX_VALID_INPUT_LENGTH) return -1;

    var parent: [MAX_N]usize = @splat(0);
    var rank: [MAX_N]u32 = @splat(0);
    for (0..n) |element| parent[element] = element;
    for (0..merge_count) |merge_index| {
        const position = 2 + 2 * merge_index;
        const first_value = input[position];
        const second_value = input[position + 1];
        if (first_value < 0 or first_value >= input[0] or second_value < 0 or second_value >= input[0]) return -1;
        const first_root = findRoot(&parent, @intCast(first_value));
        const second_root = findRoot(&parent, @intCast(second_value));
        if (first_root == second_root) continue;
        if (rank[first_root] < rank[second_root]) {
            parent[first_root] = second_root;
        } else if (rank[first_root] > rank[second_root]) {
            parent[second_root] = first_root;
        } else {
            parent[first_root] = second_root;
            rank[second_root] += 1;
        }
    }
    const query = input[2 + 2 * merge_count];
    if (query < 0 or query >= input[0]) return -1;
    return @intCast(findRoot(&parent, @intCast(query)));
}
