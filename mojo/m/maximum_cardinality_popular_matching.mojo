# Bounded clean-room strict-list maximum-cardinality popular matching.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn mp_augment(
    applicant: Int, posts: Int, first: List[Int], second: List[Int],
    mut owner: List[Int], mut assignment: List[Int], mut seen: List[Bool],
) -> Bool:
    var edges = List[Int]()
    edges.append(first[applicant])
    if second[applicant] < posts: edges.append(second[applicant])
    if edges.len() == 2 and edges[1] < edges[0]:
        var temp = edges[0]
        edges[0] = edges[1]
        edges[1] = temp
    for post in edges:
        if seen[post]: continue
        seen[post] = True
        let previous = owner[post]
        if previous < 0 or mp_augment(previous, posts, first, second, owner, assignment, seen):
            owner[post] = applicant
            assignment[applicant] = post
            return True
    return False

fn mp_solve(applicants: Int, posts: Int, preferences: List[Int], lengths: List[Int]) -> Int64:
    var first = List[Int](length=6, fill=0)
    var second = List[Int](length=6, fill=0)
    var first_post = List[Bool](length=6, fill=False)
    for a in range(applicants):
        first[a] = preferences[a * 6]
        first_post[first[a]] = True
    for a in range(applicants):
        second[a] = posts + a
        for j in range(lengths[a]):
            let candidate = preferences[a * 6 + j]
            if not first_post[candidate]:
                second[a] = candidate
                break

    var active_a = List[Bool](length=6, fill=False)
    var active_p = List[Bool](length=6, fill=False)
    var assignment = List[Int](length=6, fill=-1)
    for a in range(applicants): active_a[a] = second[a] < posts
    for p in range(posts): active_p[p] = True
    while True:
        var degree = List[Int](length=6, fill=0)
        var sole = List[Int](length=6, fill=-1)
        for a in range(applicants):
            if active_a[a]:
                for post in (first[a], second[a]):
                    if active_p[post]:
                        degree[post] += 1
                        sole[post] = a
        var forced = -1
        for p in range(posts):
            if active_p[p] and degree[p] == 1:
                forced = p
                break
        if forced < 0: break
        let a = sole[forced]
        assignment[a] = forced
        active_a[a] = False
        active_p[forced] = False

    var degree = List[Int](length=6, fill=0)
    var neighbors = List[List[Int]]()
    for p in range(6): neighbors.append(List[Int]())
    var active_count = 0
    for a in range(applicants):
        if active_a[a]:
            active_count += 1
            for post in (first[a], second[a]):
                if not active_p[post]: return 0
                neighbors[post].append(a)
                degree[post] += 1
    var residual_posts = 0
    for p in range(posts):
        if active_p[p] and degree[p] > 0:
            residual_posts += 1
            if degree[p] != 2 or neighbors[p].len() != 2: return 0
    if residual_posts < active_count or residual_posts != active_count: return 0

    var visited = List[Bool](length=6, fill=False)
    for root in range(applicants):
        if active_a[root] and not visited[root]:
            var current_post = min(first[root], second[root])
            assignment[root] = current_post
            visited[root] = True
            var current_a = root
            while True:
                let next_a = if neighbors[current_post][0] != current_a then neighbors[current_post][0] else neighbors[current_post][1]
                if next_a == root: break
                if visited[next_a]: return 0
                let next_post = if first[next_a] == current_post then second[next_a] else first[next_a]
                assignment[next_a] = next_post
                visited[next_a] = True
                current_a = next_a
                current_post = next_post

    var owner = List[Int](length=6, fill=-1)
    for a in range(applicants):
        if assignment[a] >= 0: owner[assignment[a]] = a
    for a in range(applicants):
        if second[a] >= posts and assignment[a] < 0:
            var seen = List[Bool](length=6, fill=False)
            _ = mp_augment(a, posts, first, second, owner, assignment, seen)
    for a in range(applicants):
        if assignment[a] < 0: assignment[a] = posts + a
    for p in range(posts):
        if first_post[p] and owner[p] < 0:
            var a = 0
            while first[a] != p: a += 1
            let old = assignment[a]
            if old < posts: owner[old] = -1
            assignment[a] = p
            owner[p] = a
    var result = 0
    for a in range(applicants):
        if assignment[a] < posts: result += 1
    return Int64(result)

@export("maximum_cardinality_popular_matching")
fn maximum_cardinality_popular_matching(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 45: return -1
    let applicants64 = input[0]
    let posts64 = input[1]
    if applicants64 < 1 or applicants64 > 6 or posts64 < 1 or posts64 > 6: return -1
    let applicants = Int(applicants64)
    let posts = Int(posts64)
    if length < c_size_t(2 + applicants): return -1
    var lengths = List[Int](length=6, fill=0)
    var total = 0
    for a in range(applicants):
        let size = input[2 + a]
        if size < 1 or size > posts64: return -1
        lengths[a] = Int(size)
        total += Int(size)
    if length != c_size_t(2 + applicants + total): return -1
    var preferences = List[Int](length=36, fill=0)
    var cursor = 2 + applicants
    for a in range(applicants):
        for j in range(lengths[a]):
            let value = input[cursor]
            cursor += 1
            if value < 0 or value >= posts64: return -1
            let post = Int(value)
            for k in range(j):
                if preferences[a * 6 + k] == post: return -1
            preferences[a * 6 + j] = post
    return mp_solve(applicants, posts, preferences, lengths)
