/// Three-state perfect phylogeny via Gusfield–Wu expanded-column 2-SAT.
const MAX_TAXA: usize = 8;
const MAX_CHARACTERS: usize = 8;
const MAX_LITERALS: usize = 48;
const MAX_INPUT: usize = 67;
type Graph = [[bool; MAX_LITERALS]; MAX_LITERALS];

fn add_clause(graph: &mut Graph, reverse: &mut Graph, left: usize, right: usize) {
    let from_left = left ^ 1;
    let from_right = right ^ 1;
    graph[from_left][right] = true;
    reverse[right][from_left] = true;
    graph[from_right][left] = true;
    reverse[left][from_right] = true;
}

fn solve(values: &[i64]) -> i64 {
    if values.len() < 2 || values.len() > MAX_INPUT { return -1; }
    let (taxa_raw, characters_raw) = (values[0], values[1]);
    if !(1..=MAX_TAXA as i64).contains(&taxa_raw)
        || !(0..=MAX_CHARACTERS as i64).contains(&characters_raw) { return -1; }
    let (taxa, characters) = (taxa_raw as usize, characters_raw as usize);
    if values.len() != 2 + taxa * characters { return -1; }

    let mut masks = [[0u16; 3]; MAX_CHARACTERS];
    for taxon in 0..taxa {
        for character in 0..characters {
            let state = values[2 + taxon * characters + character];
            if !(0..=2).contains(&state) { return -1; }
            masks[character][state as usize] |= 1u16 << taxon;
        }
    }

    let mut graph: Graph = [[false; MAX_LITERALS]; MAX_LITERALS];
    let mut reverse: Graph = [[false; MAX_LITERALS]; MAX_LITERALS];
    for character in 0..characters {
        let v0 = 3 * character;
        add_clause(&mut graph, &mut reverse, 2 * v0, 2 * (v0 + 1));
        add_clause(&mut graph, &mut reverse, 2 * v0, 2 * (v0 + 2));
        add_clause(&mut graph, &mut reverse, 2 * (v0 + 1), 2 * (v0 + 2));
        let mut missing = 0;
        let mut present = 0;
        for state in 0..3 {
            if masks[character][state] == 0 { missing = state; } else { present += 1; }
        }
        if present == 2 {
            let absent_literal = 2 * (3 * character + missing) + 1;
            add_clause(&mut graph, &mut reverse, absent_literal, absent_literal);
        }
    }
    let universe = (1u16 << taxa) - 1;
    for left_character in 0..characters {
        for right_character in left_character + 1..characters {
            for left_state in 0..3 {
                let left = masks[left_character][left_state];
                for right_state in 0..3 {
                    let right = masks[right_character][right_state];
                    let all_four = left & right != 0
                        && left & universe & !right != 0
                        && right & universe & !left != 0
                        && universe & !(left | right) != 0;
                    if all_four {
                        let left_variable = 3 * left_character + left_state;
                        let right_variable = 3 * right_character + right_state;
                        add_clause(&mut graph, &mut reverse,
                                   2 * left_variable + 1, 2 * right_variable + 1);
                    }
                }
            }
        }
    }

    let literal_count = 6 * characters;
    let mut seen = [false; MAX_LITERALS];
    let mut order = [0usize; MAX_LITERALS];
    let mut stack = [0usize; MAX_LITERALS];
    let mut next_index = [0usize; MAX_LITERALS];
    let mut order_count = 0;
    for start in 0..literal_count {
        if seen[start] { continue; }
        let mut top = 1;
        stack[0] = start;
        seen[start] = true;
        while top > 0 {
            let vertex = stack[top - 1];
            let mut next = next_index[vertex];
            while next < literal_count && (!graph[vertex][next] || seen[next]) { next += 1; }
            if next < literal_count {
                next_index[vertex] = next + 1;
                seen[next] = true;
                stack[top] = next;
                top += 1;
            } else {
                order[order_count] = vertex;
                order_count += 1;
                top -= 1;
            }
        }
    }
    let mut component = [-1i16; MAX_LITERALS];
    let mut label: i16 = 0;
    while order_count > 0 {
        order_count -= 1;
        let start = order[order_count];
        if component[start] >= 0 { continue; }
        let mut top = 1;
        stack[0] = start;
        component[start] = label;
        while top > 0 {
            top -= 1;
            let vertex = stack[top];
            for next in 0..literal_count {
                if reverse[vertex][next] && component[next] < 0 {
                    component[next] = label;
                    stack[top] = next;
                    top += 1;
                }
            }
        }
        label += 1;
    }
    for variable in 0..3 * characters {
        if component[2 * variable] == component[2 * variable + 1] { return 0; }
    }
    1
}

#[no_mangle]
pub unsafe extern "C" fn perfect_phylogeny_three_state_2sat(
    input: *const i64,
    length: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    solve(std::slice::from_raw_parts(input, length))
}
