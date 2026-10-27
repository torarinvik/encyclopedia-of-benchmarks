const MAX_STATES: usize = 4;
const MAX_ACTIONS: usize = 3;
const MAX_INPUT: usize = 29;
const MAX_OUTPUT: usize = 72;

unsafe fn put64(output: *mut u8, at: usize, value: i64) {
    let bits = value as u64;
    for b in 0..8 { *output.add(at + b) = (bits >> (8 * b)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn mdp_value_iteration_deterministic(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 7 || length > MAX_INPUT { return -1; }
    let states64=*input;let actions64=*input.add(1);let horizon64=*input.add(2);let p=*input.add(3);let q=*input.add(4);
    if states64<1||states64>4||actions64<1||actions64>3||horizon64<1||horizon64>8||q<1||q>4||p<0||p>=q||length!=5+2*states64 as usize*actions64 as usize{return -1;}
    let states=states64 as usize;let actions=actions64 as usize;let horizon=horizon64 as usize;
    let mut rewards=[[0_i64;MAX_ACTIONS];MAX_STATES];let mut targets=[[0_usize;MAX_ACTIONS];MAX_STATES];let mut at=5;
    for s in 0..states {for a in 0..actions {let r=*input.add(at);let next=*input.add(at+1);at+=2;if r< -100||r>100||next<0||next>=states64{return -1;}rewards[s][a]=r;targets[s][a]=next as usize;}}
    let mut scale=1_i64;for _ in 0..horizon{scale*=q;}
    let mut value=[0_i64;MAX_STATES];let mut next_value=[0_i64;MAX_STATES];let mut policy=[0_i64;MAX_STATES];
    for _ in 0..horizon {for s in 0..states {let mut best=i64::MIN;let mut best_action=0;for a in 0..actions{let candidate=rewards[s][a]*scale+p*(value[targets[s][a]]/q);if candidate>best{best=candidate;best_action=a;}}next_value[s]=best;policy[s]=best_action as i64;}for s in 0..states{value[s]=next_value[s];}}
    let bytes=8*(1+2*states);if output.is_null()||capacity<bytes{return -2;}let mut staged=[0_u8;MAX_OUTPUT];put64(staged.as_mut_ptr(),0,scale);for s in 0..states{put64(staged.as_mut_ptr(),8*(1+s),value[s]);put64(staged.as_mut_ptr(),8*(1+states+s),policy[s]);}for b in 0..bytes{*output.add(b)=staged[b];}bytes as i64
}
