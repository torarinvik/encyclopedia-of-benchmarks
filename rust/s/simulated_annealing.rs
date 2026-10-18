const MAX_PACKED_LENGTH: usize = 366;
const MAX_DRAWS: i64 = 176;
const MAX_ITERATIONS: i64 = 22;
const INVALID_RESULT: i64 = -1;

fn score_i64(x: i64, y: i64) -> i64 { x * x + y * y }

#[no_mangle]
pub unsafe extern "C" fn simulated_annealing(packed: *const i64, length: usize) -> i64 {
    if packed.is_null() || length < 13 || length > MAX_PACKED_LENGTH { return INVALID_RESULT; }
    let packed = std::slice::from_raw_parts(packed, length);
    let (x0,y0,step)=(packed[0],packed[1],packed[2]);
    let (min_x,max_x,min_y,max_y)=(packed[3],packed[4],packed[5],packed[6]);
    let (find_max,start_raw,rate_raw,threshold_raw,selection_count)=(packed[7],packed[8],packed[9],packed[10],packed[11]);
    if !(-16..=16).contains(&x0) || !(-16..=16).contains(&y0) || !(1..=4).contains(&step) ||
        !(-16..=16).contains(&min_x) || !(-16..=16).contains(&max_x) || min_x>max_x ||
        !(-16..=16).contains(&min_y) || !(-16..=16).contains(&max_y) || min_y>max_y ||
        !(min_x..=max_x).contains(&x0) || !(min_y..=max_y).contains(&y0) || !(0..=1).contains(&find_max) ||
        !(1_000_000..=10_000_000).contains(&start_raw) || !(100_000..=500_000).contains(&rate_raw) ||
        !(1_000_000..=9_999_999).contains(&threshold_raw) || threshold_raw>=start_raw ||
        !(0..=MAX_DRAWS).contains(&selection_count) || selection_count as usize>length-13 { return INVALID_RESULT; }
    let selection_n=selection_count as usize;
    let acceptance_count_index=12+selection_n;
    let acceptance_count=packed[acceptance_count_index];
    if !(0..=MAX_DRAWS).contains(&acceptance_count) || length!=13+selection_n+acceptance_count as usize { return INVALID_RESULT; }
    if packed[12..12+selection_n].iter().any(|&x| !(0..=7).contains(&x)) { return INVALID_RESULT; }
    let acceptance_start=acceptance_count_index+1;
    if packed[acceptance_start..].iter().any(|&x| x!=0&&x!=999_999) { return INVALID_RESULT; }

    let mut current_temp=start_raw as f64/1_000_000.0;
    let rate=rate_raw as f64/1_000_000.0;
    let threshold=threshold_raw as f64/1_000_000.0;
    let (mut current_x,mut current_y)=(x0,y0);
    let (mut best_x,mut best_y)=(x0,y0);
    let mut best_score=score_i64(x0,y0);
    let (mut selection_cursor,mut acceptance_cursor)=(0usize,0usize);
    let mut stopped=false;
    for _ in 0..MAX_ITERATIONS {
        let current_score=score_i64(current_x,current_y);
        if current_score>best_score { best_score=current_score; best_x=current_x; best_y=current_y; }
        let mut nx=[current_x-step,current_x-step,current_x-step,current_x,current_x,current_x+step,current_x+step,current_x+step];
        let mut ny=[current_y-step,current_y,current_y+step,current_y-step,current_y+step,current_y-step,current_y,current_y+step];
        let mut remaining=8usize;
        let mut found=false;
        let (mut next_x,mut next_y)=(0,0);
        while !found&&remaining>0 {
            if selection_cursor>=selection_n { return INVALID_RESULT; }
            let rank=packed[12+selection_cursor] as usize; selection_cursor+=1;
            if rank>=remaining { return INVALID_RESULT; }
            let candidate=(nx[rank],ny[rank]);
            let raw_change=score_i64(candidate.0,candidate.1)-current_score;
            for i in rank+1..remaining { nx[i-1]=nx[i]; ny[i-1]=ny[i]; }
            remaining-=1;
            if candidate.0<min_x||candidate.0>max_x||candidate.1<min_y||candidate.1>max_y { continue; }
            let change=if find_max==1 { raw_change } else { -raw_change };
            if change>0 { found=true; }
            else {
                if acceptance_cursor>=acceptance_count as usize { return INVALID_RESULT; }
                let draw=packed[acceptance_start+acceptance_cursor]; acceptance_cursor+=1;
                if change==0||draw==0 { found=true; }
            }
            if found { next_x=candidate.0; next_y=candidate.1; }
        }
        current_temp=current_temp-current_temp*rate;
        if current_temp<threshold||!found { stopped=true; break; }
        current_x=next_x; current_y=next_y;
    }
    if !stopped { return INVALID_RESULT; }
    (best_x+16)*33+(best_y+16)
}
