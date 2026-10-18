module simulated_annealing

const max_packed_length = 366
const max_draws = i64(176)
const max_iterations = 22
const invalid_result = i64(-1)

fn score_i64(x i64, y i64) i64 { return x*x + y*y }

@[export: 'simulated_annealing']
pub fn simulated_annealing(packed &i64, length usize) i64 {
	unsafe {
		if packed == nil || length < 13 || length > max_packed_length { return invalid_result }
		x0,y0,step := packed[0],packed[1],packed[2]
		min_x,max_x,min_y,max_y := packed[3],packed[4],packed[5],packed[6]
		find_max,start_raw,rate_raw,threshold_raw,selection_count := packed[7],packed[8],packed[9],packed[10],packed[11]
		if x0 < -16 || x0 > 16 || y0 < -16 || y0 > 16 || step < 1 || step > 4 ||
			min_x < -16 || max_x > 16 || min_x > max_x || min_y < -16 || max_y > 16 || min_y > max_y ||
			x0 < min_x || x0 > max_x || y0 < min_y || y0 > max_y || (find_max != 0 && find_max != 1) ||
			start_raw < 1000000 || start_raw > 10000000 || rate_raw < 100000 || rate_raw > 500000 ||
			threshold_raw < 1000000 || threshold_raw > 9999999 || threshold_raw >= start_raw ||
			selection_count < 0 || selection_count > max_draws || usize(selection_count) > length-13 { return invalid_result }
		selection_n := int(selection_count)
		acceptance_count_index := 12 + selection_n
		acceptance_count := packed[acceptance_count_index]
		if acceptance_count < 0 || acceptance_count > max_draws || length != usize(13+selection_count+acceptance_count) { return invalid_result }
		for i in 0 .. selection_n { if packed[12+i] < 0 || packed[12+i] > 7 { return invalid_result } }
		acceptance_start := acceptance_count_index + 1
		for i in 0 .. int(acceptance_count) { draw := packed[acceptance_start+i];if draw != 0 && draw != 999999 { return invalid_result } }

		mut current_temp := f64(start_raw) / 1000000.0
		rate := f64(rate_raw) / 1000000.0
		threshold := f64(threshold_raw) / 1000000.0
		mut current_x,current_y,best_x,best_y := x0,y0,x0,y0
		mut best_score := score_i64(x0,y0)
		mut selection_cursor,acceptance_cursor := 0,0
		mut stopped := false
		for _ in 0 .. max_iterations {
			current_score := score_i64(current_x,current_y)
			if current_score > best_score { best_score=current_score;best_x=current_x;best_y=current_y }
			mut nx := [current_x-step,current_x-step,current_x-step,current_x,current_x,current_x+step,current_x+step,current_x+step]
			mut ny := [current_y-step,current_y,current_y+step,current_y-step,current_y+step,current_y-step,current_y,current_y+step]
			mut remaining := 8
			mut found := false
			mut next_x,next_y := i64(0),i64(0)
			for !found && remaining > 0 {
				if selection_cursor >= selection_n { return invalid_result }
				rank := int(packed[12+selection_cursor]);selection_cursor++
				if rank >= remaining { return invalid_result }
				candidate_x,candidate_y := nx[rank],ny[rank]
				raw_change := score_i64(candidate_x,candidate_y)-current_score
				for i in rank+1 .. remaining { nx[i-1]=nx[i];ny[i-1]=ny[i] }
				remaining--
				if candidate_x < min_x || candidate_x > max_x || candidate_y < min_y || candidate_y > max_y { continue }
				change := raw_change
				if find_max == 0 { change = -raw_change }
				if change > 0 { found=true } else {
					if acceptance_cursor >= int(acceptance_count) { return invalid_result }
					draw := packed[acceptance_start+acceptance_cursor];acceptance_cursor++
					if change == 0 || draw == 0 { found=true }
				}
				if found { next_x=candidate_x;next_y=candidate_y }
			}
			current_temp = current_temp - current_temp*rate
			if current_temp < threshold || !found { stopped=true;break }
			current_x,current_y = next_x,next_y
		}
		if !stopped { return invalid_result }
		return (best_x+16)*33+(best_y+16)
	}
}
