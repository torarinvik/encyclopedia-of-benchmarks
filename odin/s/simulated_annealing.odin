package simulated_annealing

import "core:c"

MAX_PACKED_LENGTH :: c.size_t(366)
MAX_DRAWS :: i64(176)
MAX_ITERATIONS :: i64(22)
INVALID_RESULT :: i64 = -1

score_i64 :: proc "contextless" (x, y: i64) -> i64 { return x*x + y*y }

@(export)
simulated_annealing :: proc "c" (packed: [^]i64, length: c.size_t) -> i64 {
	if packed == nil || length < 13 || length > MAX_PACKED_LENGTH do return INVALID_RESULT
	x0,y0,step := packed[0],packed[1],packed[2]
	min_x,max_x,min_y,max_y := packed[3],packed[4],packed[5],packed[6]
	find_max,start_raw,rate_raw,threshold_raw,selection_count := packed[7],packed[8],packed[9],packed[10],packed[11]
	if x0 < -16 || x0 > 16 || y0 < -16 || y0 > 16 || step < 1 || step > 4 ||
		min_x < -16 || max_x > 16 || min_x > max_x || min_y < -16 || max_y > 16 || min_y > max_y ||
		x0 < min_x || x0 > max_x || y0 < min_y || y0 > max_y || (find_max != 0 && find_max != 1) ||
		start_raw < 1000000 || start_raw > 10000000 || rate_raw < 100000 || rate_raw > 500000 ||
		threshold_raw < 1000000 || threshold_raw > 9999999 || threshold_raw >= start_raw ||
		selection_count < 0 || selection_count > MAX_DRAWS || c.size_t(selection_count) > length-13 do return INVALID_RESULT
	selection_n := c.size_t(selection_count)
	acceptance_count_index := c.size_t(12)+selection_n
	acceptance_count := packed[acceptance_count_index]
	if acceptance_count < 0 || acceptance_count > MAX_DRAWS || length != c.size_t(13)+selection_n+c.size_t(acceptance_count) do return INVALID_RESULT
	for i:c.size_t=0;i<selection_n;i+=1 { if packed[12+i] < 0 || packed[12+i] > 7 do return INVALID_RESULT }
	acceptance_start := acceptance_count_index+1
	for i:c.size_t=0;i<c.size_t(acceptance_count);i+=1 { draw:=packed[acceptance_start+i];if draw!=0&&draw!=999999 do return INVALID_RESULT }

	current_temp:=f64(start_raw)/1_000_000.0
	rate:=f64(rate_raw)/1_000_000.0
	threshold:=f64(threshold_raw)/1_000_000.0
	current_x,current_y,best_x,best_y:=x0,y0,x0,y0
	best_score:=score_i64(x0,y0)
	selection_cursor,acceptance_cursor:=c.size_t(0),c.size_t(0)
	stopped:=false
	for iteration:i64=0;iteration<MAX_ITERATIONS;iteration+=1 {
		current_score:=score_i64(current_x,current_y)
		if current_score>best_score { best_score=current_score;best_x=current_x;best_y=current_y }
		nx:=[8]i64{current_x-step,current_x-step,current_x-step,current_x,current_x,current_x+step,current_x+step,current_x+step}
		ny:=[8]i64{current_y-step,current_y,current_y+step,current_y-step,current_y+step,current_y-step,current_y,current_y+step}
		remaining:=c.size_t(8)
		found:=false
		next_x,next_y:=i64(0),i64(0)
		for !found&&remaining>0 {
			if selection_cursor>=selection_n do return INVALID_RESULT
			rank:=packed[12+selection_cursor];selection_cursor+=1
			if c.size_t(rank)>=remaining do return INVALID_RESULT
			selected:=c.size_t(rank)
			candidate_x,candidate_y:=nx[selected],ny[selected]
			raw_change:=score_i64(candidate_x,candidate_y)-current_score
			for i:=selected+1;i<remaining;i+=1 { nx[i-1]=nx[i];ny[i-1]=ny[i] }
			remaining-=1
			if candidate_x<min_x||candidate_x>max_x||candidate_y<min_y||candidate_y>max_y do continue
			change:=raw_change;if find_max==0 do change=-raw_change
			if change>0 { found=true } else {
				if acceptance_cursor>=c.size_t(acceptance_count) do return INVALID_RESULT
				draw:=packed[acceptance_start+acceptance_cursor];acceptance_cursor+=1
				if change==0||draw==0 do found=true
			}
			if found { next_x=candidate_x;next_y=candidate_y }
		}
		current_temp=current_temp-current_temp*rate
		if current_temp<threshold||!found { stopped=true;break }
		current_x,current_y=next_x,next_y
	}
	if !stopped do return INVALID_RESULT
	return (best_x+16)*33+(best_y+16)
}
