// Bounded clean-room strict-list maximum-cardinality popular matching.
const std = @import("std");
const A = 6;
const P = 6;

fn augment(applicant: usize, posts: usize, first: *const [A]usize,
    second: *const [A]usize, owner: *[P]i32, assignment: *[A]i32,
    seen: *[P]bool) bool {
    var edges = [_]usize{ first[applicant], P };
    var count: usize = 1;
    if (second[applicant] < posts) { edges[1] = second[applicant]; count = 2; }
    if (count == 2 and edges[1] < edges[0]) std.mem.swap(usize, &edges[0], &edges[1]);
    for (0..count) |i| {
        const post = edges[i];
        if (seen[post]) continue;
        seen[post] = true;
        const previous = owner[post];
        if (previous < 0 or augment(@intCast(previous), posts, first, second, owner, assignment, seen)) {
            owner[post] = @intCast(applicant);
            assignment[applicant] = @intCast(post);
            return true;
        }
    }
    return false;
}

fn solve(applicants: usize, posts: usize, preferences: *const [A][P]usize,
    lengths: *const [A]usize) i64 {
    var first = [_]usize{0} ** A;
    var second = [_]usize{0} ** A;
    var first_post = [_]bool{false} ** P;
    for (0..applicants) |a| { first[a] = preferences[a][0]; first_post[first[a]] = true; }
    for (0..applicants) |a| {
        second[a] = posts + a;
        for (0..lengths[a]) |j| {
            const candidate = preferences[a][j];
            if (!first_post[candidate]) { second[a] = candidate; break; }
        }
    }
    var active_a = [_]bool{false} ** A;
    var active_p = [_]bool{false} ** P;
    var assignment = [_]i32{-1} ** A;
    for (0..applicants) |a| active_a[a] = second[a] < posts;
    for (0..posts) |p| active_p[p] = true;

    while (true) {
        var degree = [_]usize{0} ** P;
        var sole = [_]i32{-1} ** P;
        for (0..applicants) |a| if (active_a[a]) {
            for ([_]usize{ first[a], second[a] }) |post| if (active_p[post]) {
                degree[post] += 1;
                sole[post] = @intCast(a);
            };
        };
        var forced: ?usize = null;
        for (0..posts) |p| if (active_p[p] and degree[p] == 1) { forced = p; break; };
        if (forced) |post| {
            const a: usize = @intCast(sole[post]);
            assignment[a] = @intCast(post);
            active_a[a] = false;
            active_p[post] = false;
        } else break;
    }

    var degree = [_]usize{0} ** P;
    var neighbors = [_][2]i32{[_]i32{-1} ** 2} ** P;
    var neighbor_count = [_]usize{0} ** P;
    var active_count: usize = 0;
    for (0..applicants) |a| if (active_a[a]) {
        active_count += 1;
        for ([_]usize{ first[a], second[a] }) |post| {
            if (!active_p[post]) return 0;
            if (neighbor_count[post] < 2) neighbors[post][neighbor_count[post]] = @intCast(a);
            neighbor_count[post] += 1;
            degree[post] += 1;
        }
    };
    var residual_posts: usize = 0;
    for (0..posts) |post| if (active_p[post] and degree[post] > 0) {
        residual_posts += 1;
        if (degree[post] != 2 or neighbor_count[post] != 2) return 0;
    };
    if (residual_posts < active_count or residual_posts != active_count) return 0;

    var visited = [_]bool{false} ** A;
    for (0..applicants) |root| if (active_a[root] and !visited[root]) {
        var current_post = @min(first[root], second[root]);
        assignment[root] = @intCast(current_post);
        visited[root] = true;
        var current_a = root;
        while (true) {
            const next_a: usize = @intCast(if (neighbors[current_post][0] != @as(i32, @intCast(current_a)))
                neighbors[current_post][0] else neighbors[current_post][1]);
            if (next_a == root) break;
            if (visited[next_a]) return 0;
            const next_post = if (first[next_a] == current_post) second[next_a] else first[next_a];
            assignment[next_a] = @intCast(next_post);
            visited[next_a] = true;
            current_a = next_a;
            current_post = next_post;
        }
    };

    var owner = [_]i32{-1} ** P;
    for (0..applicants) |a| if (assignment[a] >= 0) owner[@intCast(assignment[a])] = @intCast(a);
    for (0..applicants) |a| if (second[a] >= posts and assignment[a] < 0) {
        var seen = [_]bool{false} ** P;
        _ = augment(a, posts, &first, &second, &owner, &assignment, &seen);
    };
    for (0..applicants) |a| if (assignment[a] < 0) assignment[a] = @intCast(posts + a);
    for (0..posts) |post| if (first_post[post] and owner[post] < 0) {
        var a: usize = 0;
        while (first[a] != post) : (a += 1) {}
        const old = assignment[a];
        if (old < @as(i32, @intCast(posts))) owner[@intCast(old)] = -1;
        assignment[a] = @intCast(post);
        owner[post] = @intCast(a);
    };
    var result: i64 = 0;
    for (0..applicants) |a| if (assignment[a] < @as(i32, @intCast(posts))) { result += 1; };
    return result;
}

export fn maximum_cardinality_popular_matching(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > 45) return -1;
    const values = input.?;
    if (values[0] < 1 or values[0] > A or values[1] < 1 or values[1] > P) return -1;
    const applicants: usize = @intCast(values[0]);
    const posts: usize = @intCast(values[1]);
    if (length < 2 + applicants) return -1;
    var lengths = [_]usize{0} ** A;
    var total: usize = 0;
    for (0..applicants) |a| {
        const size = values[2 + a];
        if (size < 1 or size > posts) return -1;
        lengths[a] = @intCast(size);
        total += lengths[a];
    }
    if (length != 2 + applicants + total) return -1;
    var preferences = [_][P]usize{[_]usize{0} ** P} ** A;
    var cursor: usize = 2 + applicants;
    for (0..applicants) |a| for (0..lengths[a]) |j| {
        const value = values[cursor];
        cursor += 1;
        if (value < 0 or value >= posts) return -1;
        const post: usize = @intCast(value);
        for (0..j) |k| if (preferences[a][k] == post) return -1;
        preferences[a][j] = post;
    };
    return solve(applicants, posts, &preferences, &lengths);
}
