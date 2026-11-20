// Bounded clean-room strict-list maximum-cardinality popular matching.
const A: usize = 6;
const P: usize = 6;

fn augment(applicant: usize, posts: usize, first: &[usize; A], second: &[usize; A],
           owner: &mut [i32; P], assignment: &mut [i32; A], seen: &mut [bool; P]) -> bool {
    let mut edges = [first[applicant], P];
    let count = if second[applicant] < posts {
        edges[1] = second[applicant]; 2
    } else { 1 };
    if count == 2 && edges[1] < edges[0] { edges.swap(0, 1); }
    for &post in edges.iter().take(count) {
        if seen[post] { continue; }
        seen[post] = true;
        let previous = owner[post];
        if previous < 0 || augment(previous as usize, posts, first, second, owner, assignment, seen) {
            owner[post] = applicant as i32;
            assignment[applicant] = post as i32;
            return true;
        }
    }
    false
}

fn solve(applicants: usize, posts: usize, preferences: &[[usize; P]; A], lengths: &[usize; A]) -> i64 {
    let mut first = [0usize; A];
    let mut second = [0usize; A];
    let mut first_post = [false; P];
    for a in 0..applicants { first[a] = preferences[a][0]; first_post[first[a]] = true; }
    for a in 0..applicants {
        second[a] = posts + a;
        for &candidate in preferences[a].iter().take(lengths[a]) {
            if !first_post[candidate] { second[a] = candidate; break; }
        }
    }

    let mut active_a = [false; A];
    let mut active_p = [false; P];
    let mut assignment = [-1i32; A];
    for a in 0..applicants { active_a[a] = second[a] < posts; }
    for p in 0..posts { active_p[p] = true; }
    loop {
        let mut degree = [0usize; P];
        let mut sole = [-1i32; P];
        for a in 0..applicants { if active_a[a] {
            for post in [first[a], second[a]] { if active_p[post] {
                degree[post] += 1; sole[post] = a as i32;
            }}
        }}
        let forced = (0..posts).find(|&p| active_p[p] && degree[p] == 1);
        let Some(post) = forced else { break; };
        let a = sole[post] as usize;
        assignment[a] = post as i32;
        active_a[a] = false;
        active_p[post] = false;
    }

    let mut degree = [0usize; P];
    let mut neighbors = [[-1i32; 2]; P];
    let mut neighbor_count = [0usize; P];
    let active_applicants: Vec<usize> = (0..applicants).filter(|&a| active_a[a]).collect();
    for &a in &active_applicants {
        for post in [first[a], second[a]] {
            if !active_p[post] { return 0; }
            if neighbor_count[post] < 2 { neighbors[post][neighbor_count[post]] = a as i32; }
            neighbor_count[post] += 1;
            degree[post] += 1;
        }
    }
    let residual_posts: Vec<usize> = (0..posts).filter(|&p| active_p[p] && degree[p] > 0).collect();
    if residual_posts.len() < active_applicants.len() || residual_posts.len() != active_applicants.len()
        || residual_posts.iter().any(|&p| degree[p] != 2 || neighbor_count[p] != 2) { return 0; }

    let mut visited = [false; A];
    for root in 0..applicants { if active_a[root] && !visited[root] {
        let mut current_p = first[root].min(second[root]);
        assignment[root] = current_p as i32;
        visited[root] = true;
        let mut current_a = root;
        loop {
            let next_a = if neighbors[current_p][0] as usize != current_a {
                neighbors[current_p][0] as usize
            } else { neighbors[current_p][1] as usize };
            if next_a == root { break; }
            if visited[next_a] { return 0; }
            let next_p = if first[next_a] == current_p { second[next_a] } else { first[next_a] };
            assignment[next_a] = next_p as i32;
            visited[next_a] = true;
            current_a = next_a;
            current_p = next_p;
        }
    }}

    let mut owner = [-1i32; P];
    for a in 0..applicants { if assignment[a] >= 0 { owner[assignment[a] as usize] = a as i32; } }
    for a in 0..applicants { if second[a] >= posts && assignment[a] < 0 {
        let mut seen = [false; P];
        augment(a, posts, &first, &second, &mut owner, &mut assignment, &mut seen);
    }}
    for a in 0..applicants { if assignment[a] < 0 { assignment[a] = (posts + a) as i32; } }
    for post in 0..posts { if first_post[post] && owner[post] < 0 {
        let a = (0..applicants).find(|&a| first[a] == post).unwrap();
        let old = assignment[a];
        if old < posts as i32 { owner[old as usize] = -1; }
        assignment[a] = post as i32;
        owner[post] = a as i32;
    }}
    assignment[..applicants].iter().filter(|&&post| post < posts as i32).count() as i64
}

#[no_mangle]
pub unsafe extern "C" fn maximum_cardinality_popular_matching(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > 45 { return -1; }
    let av = *input;
    let pv = *input.add(1);
    if av < 1 || av > A as i64 || pv < 1 || pv > P as i64 { return -1; }
    let applicants = av as usize;
    let posts = pv as usize;
    if length < 2 + applicants { return -1; }
    let mut lengths = [0usize; A];
    let mut total = 0usize;
    for a in 0..applicants {
        let size = *input.add(2 + a);
        if size < 1 || size > posts as i64 { return -1; }
        lengths[a] = size as usize;
        total += lengths[a];
    }
    if length != 2 + applicants + total { return -1; }
    let mut preferences = [[0usize; P]; A];
    let mut cursor = 2 + applicants;
    for a in 0..applicants { for j in 0..lengths[a] {
        let value = *input.add(cursor);
        cursor += 1;
        if value < 0 || value >= posts as i64 { return -1; }
        let post = value as usize;
        if preferences[a][..j].contains(&post) { return -1; }
        preferences[a][j] = post;
    }}
    solve(applicants, posts, &preferences, &lengths)
}
