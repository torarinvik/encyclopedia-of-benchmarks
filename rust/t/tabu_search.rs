const MAX_CITIES: usize = 6;
const MAX_ROUTE: usize = 7;
const MAX_CANDIDATES: usize = 10;
const MAX_OUTPUT: usize = 36;

fn route_cost(route: &[i32; MAX_ROUTE], length: usize, edge: &[[i64; MAX_CITIES]; MAX_CITIES]) -> i64 {
    let mut cost = 0i64;
    for i in 0..length-1 { cost += edge[route[i] as usize][route[i+1] as usize]; }
    cost
}

fn same_route(a: &[i32; MAX_ROUTE], b: &[i32; MAX_ROUTE], length: usize) -> bool {
    for i in 0..length { if a[i] != b[i] { return false; } }
    true
}

#[no_mangle]
pub unsafe extern "C" fn tabu_search(
    input: *const i64, input_length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || !(3..=19).contains(&input_length) { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, input_length) };
    let city_value=values[0]; let iteration_value=values[1]; let tabu_value=values[2];
    if !(4..=6).contains(&city_value) || !(0..=8).contains(&iteration_value) || !(1..=3).contains(&tabu_value) { return -1; }
    let cities=city_value as usize; let iterations=iteration_value as usize; let tabu_size=tabu_value as usize;
    if input_length != 3 + cities*(cities-1)/2 { return -1; }
    let mut edge=[[0i64; MAX_CITIES]; MAX_CITIES];
    let mut offset=3;
    for left in 0..cities { for right in left+1..cities {
        let weight=values[offset]; offset+=1;
        if !(1..=99).contains(&weight) { return -1; }
        edge[left][right]=weight; edge[right][left]=weight;
    }}

    let mut solution=[0i32; MAX_ROUTE]; let mut route_len=0usize; let mut current=0i32;
    loop {
        if solution[..route_len].contains(&current) { break; }
        let mut minimum=10_000i64; let mut best_node=current;
        // The source's edge insertion order yields ascending neighbor labels.
        for node in 0..cities {
            if node==current as usize { continue; }
            if !solution[..route_len].contains(&(node as i32)) && edge[current as usize][node]<minimum {
                minimum=edge[current as usize][node]; best_node=node as i32;
            }
        }
        solution[route_len]=current; route_len+=1; current=best_node;
    }
    solution[route_len]=0; route_len+=1;
    let mut best_cost=route_cost(&solution,route_len,&edge);
    let mut best_solution=solution;
    let mut tabu_new=[0i32;3]; let mut tabu_old=[0i32;3]; let mut tabu_count=0usize;

    for _ in 0..iterations {
        let mut candidates=[[0i32;MAX_ROUTE];MAX_CANDIDATES];
        let mut costs=[0i64;MAX_CANDIDATES]; let mut candidate_count=0usize;
        for first in 1..route_len-1 { for second in 1..route_len-1 {
            if first==second { continue; }
            let mut candidate=solution;
            candidate.swap(first,second);
            let mut duplicate=false;
            for old in 0..candidate_count { if same_route(&candidate,&candidates[old],route_len) { duplicate=true; break; } }
            if !duplicate {
                candidates[candidate_count]=candidate;
                costs[candidate_count]=route_cost(&candidate,route_len,&edge);
                candidate_count+=1;
            }
        }}
        // Stable insertion sort preserves the nested swap order for equal costs.
        for i in 1..candidate_count {
            let route=candidates[i]; let cost=costs[i]; let mut j=i;
            while j>0 && cost<costs[j-1] { candidates[j]=candidates[j-1];costs[j]=costs[j-1];j-=1; }
            candidates[j]=route;costs[j]=cost;
        }
        let mut selected=0usize;
        let (move_new,move_old)=loop {
            let mut difference=0usize;
            while difference<route_len && candidates[selected][difference]==solution[difference] { difference+=1; }
            let new=candidates[selected][difference];let old=solution[difference];
            let forbidden=(0..tabu_count).any(|i| (tabu_new[i]==new&&tabu_old[i]==old)||(tabu_new[i]==old&&tabu_old[i]==new));
            if !forbidden { break (new,old); }
            selected+=1;
        };
        tabu_new[tabu_count]=move_new;tabu_old[tabu_count]=move_old;tabu_count+=1;
        solution=candidates[selected];
        let cost=costs[selected];
        if cost<best_cost { best_cost=cost;best_solution=solution; }
        if tabu_count>=tabu_size {
            for i in 1..tabu_count { tabu_new[i-1]=tabu_new[i];tabu_old[i-1]=tabu_old[i]; }
            tabu_count-=1;
        }
    }
    let mut staged=[0u8;MAX_OUTPUT]; let mut written=0usize;
    let words=[route_len as i32];
    for byte in words[0].to_le_bytes() { staged[written]=byte;written+=1; }
    for i in 0..route_len { for byte in best_solution[i].to_le_bytes() { staged[written]=byte;written+=1; } }
    for byte in (best_cost as i32).to_le_bytes() { staged[written]=byte;written+=1; }
    if output.is_null()||capacity<written { return -2; }
    unsafe { std::ptr::copy_nonoverlapping(staged.as_ptr(),output,written); }
    written as i64
}
