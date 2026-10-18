const INVALID_RESULT: i64 = -1;
const MAX_PACKED_LENGTH: usize = 16;

fn distance_i64(a: i64, b: i64) -> i64 { (a - b).abs() }

#[no_mangle]
pub unsafe extern "C" fn k_medoids(packed: *const i64, length: usize) -> i64 {
    if packed.is_null() || length < 3 || length > MAX_PACKED_LENGTH { return INVALID_RESULT; }
    let packed = std::slice::from_raw_parts(packed, length);
    let (point_count,medoid_count,max_iter)=(packed[0],packed[1],packed[2]);
    if !(2..=8).contains(&point_count) || !(1..=4).contains(&medoid_count) || medoid_count>point_count ||
        !(1..=16).contains(&max_iter) || length!= (3+medoid_count+point_count) as usize { return INVALID_RESULT; }
    let n=point_count as usize;
    let k=medoid_count as usize;
    let mut medoids=[0i64;4];
    let mut points=[0i64;8];
    let mut labels=[0i64;8];
    for slot in 0..k {
        medoids[slot]=packed[3+slot];
        if medoids[slot]<0 || medoids[slot]>=point_count || medoids[..slot].contains(&medoids[slot]) { return INVALID_RESULT; }
    }
    for i in 0..n {
        points[i]=packed[3+k+i];
        if !(-16..=16).contains(&points[i]) || points[..i].contains(&points[i]) { return INVALID_RESULT; }
    }

    for _ in 0..max_iter as usize {
        for i in 0..n {
            let mut best_slot=0usize;
            let mut best_distance=distance_i64(points[i],points[medoids[0] as usize]);
            for slot in 1..k {
                let distance=distance_i64(points[i],points[medoids[slot] as usize]);
                if distance<best_distance { best_distance=distance; best_slot=slot; }
            }
            labels[i]=best_slot as i64;
        }
        let mut updated=[0i64;4];
        for slot in 0..k {
            let mut first=n;
            for i in 0..n { if labels[i]==slot as i64 { first=i; break; } }
            if first==n { return INVALID_RESULT; }
            let mut best_index=first;
            let mut best_cost:i64=0;
            for i in 0..n { if labels[i]==slot as i64 { best_cost+=distance_i64(points[first],points[i]); } }
            for candidate in first+1..n {
                if labels[candidate]!=slot as i64 { continue; }
                let mut cost=0i64;
                for i in 0..n { if labels[i]==slot as i64 { cost+=distance_i64(points[candidate],points[i]); } }
                if cost<best_cost { best_cost=cost; best_index=candidate; }
            }
            updated[slot]=best_index as i64;
        }
        if updated[..k]==medoids[..k] { break; }
        medoids=updated;
    }

    let mut result=0i64;
    for slot in 0..k { result|=medoids[slot]<<(3*slot); }
    for i in 0..n { result|=labels[i]<<(12+2*i); }
    result
}
