package k_medoids

import "core:c"

INVALID_RESULT :: i64 = -1
MAX_PACKED_LENGTH :: c.size_t(16)

distance_i64 :: proc "contextless" (a, b: i64) -> i64 {
	if a >= b do return a-b
	return b-a
}

@(export)
k_medoids :: proc "c" (packed: [^]i64, length: c.size_t) -> i64 {
	if packed == nil || length < 3 || length > MAX_PACKED_LENGTH do return INVALID_RESULT
	point_count,medoid_count,max_iter := packed[0],packed[1],packed[2]
	if point_count < 2 || point_count > 8 || medoid_count < 1 || medoid_count > 4 || medoid_count > point_count ||
		max_iter < 1 || max_iter > 16 || length != c.size_t(3+point_count+medoid_count) do return INVALID_RESULT
	n,k := int(point_count),int(medoid_count)
	medoids := [4]i64{}
	points := [8]i64{}
	labels := [8]i64{}
	for slot:=0;slot<k;slot+=1 {
		medoids[slot]=packed[3+slot]
		if medoids[slot]<0||medoids[slot]>=point_count do return INVALID_RESULT
		for earlier:=0;earlier<slot;earlier+=1{if medoids[earlier]==medoids[slot] do return INVALID_RESULT}
	}
	for i:=0;i<n;i+=1 {
		points[i]=packed[3+k+i]
		if points[i]<-16||points[i]>16 do return INVALID_RESULT
		for earlier:=0;earlier<i;earlier+=1{if points[earlier]==points[i] do return INVALID_RESULT}
	}

	for iteration:=i64(0);iteration<max_iter;iteration+=1 {
		for i:=0;i<n;i+=1 {
			best_slot:=0
			best_distance:=distance_i64(points[i],points[int(medoids[0])])
			for slot:=1;slot<k;slot+=1{distance:=distance_i64(points[i],points[int(medoids[slot])]);if distance<best_distance{best_distance=distance;best_slot=slot}}
			labels[i]=i64(best_slot)
		}
		updated:=[4]i64{}
		for slot:=0;slot<k;slot+=1 {
			first:=n
			for i:=0;i<n;i+=1{if labels[i]==i64(slot){first=i;break}}
			if first==n do return INVALID_RESULT
			best_index:=first
			best_cost:=i64(0)
			for i:=0;i<n;i+=1{if labels[i]==i64(slot){best_cost+=distance_i64(points[first],points[i])}}
			for candidate:=first+1;candidate<n;candidate+=1 {
				if labels[candidate]!=i64(slot) do continue
				cost:=i64(0)
				for i:=0;i<n;i+=1{if labels[i]==i64(slot){cost+=distance_i64(points[candidate],points[i])}}
				if cost<best_cost{best_cost=cost;best_index=candidate}
			}
			updated[slot]=i64(best_index)
		}
		changed:=false
		for slot:=0;slot<k;slot+=1{if updated[slot]!=medoids[slot]{changed=true}}
		if !changed do break
		for slot:=0;slot<k;slot+=1{medoids[slot]=updated[slot]}
	}
	result:=i64(0)
	for slot:=0;slot<k;slot+=1{result|=medoids[slot]<<(3*slot)}
	for i:=0;i<n;i+=1{result|=labels[i]<<(12+2*i)}
	return result
}
