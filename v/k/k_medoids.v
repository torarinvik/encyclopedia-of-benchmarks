module k_medoids

const invalid_result = i64(-1)
const max_packed_length = 16

fn distance_i64(a i64, b i64) i64 { return if a >= b { a-b } else { b-a } }

@[export: 'k_medoids']
pub fn k_medoids(packed &i64, length usize) i64 {
	unsafe {
		if packed == nil || length < 3 || length > max_packed_length { return invalid_result }
		point_count,medoid_count,max_iter := packed[0],packed[1],packed[2]
		if point_count<2||point_count>8||medoid_count<1||medoid_count>4||medoid_count>point_count||max_iter<1||max_iter>16||length!=usize(3+point_count+medoid_count){return invalid_result}
		n,k:=int(point_count),int(medoid_count)
		mut medoids:=[4]i64{}
		mut points:=[8]i64{}
		mut labels:=[8]i64{}
		for slot in 0..k {
			medoids[slot]=packed[3+slot]
			if medoids[slot]<0||medoids[slot]>=point_count{return invalid_result}
			for earlier in 0..slot{if medoids[earlier]==medoids[slot]{return invalid_result}}
		}
		for i in 0..n {
			points[i]=packed[3+k+i]
			if points[i]<-16||points[i]>16{return invalid_result}
			for earlier in 0..i{if points[earlier]==points[i]{return invalid_result}}
		}
		for _ in 0..int(max_iter) {
			for i in 0..n {
				mut best_slot:=0
				mut best_distance:=distance_i64(points[i],points[int(medoids[0])])
				for slot in 1..k{distance:=distance_i64(points[i],points[int(medoids[slot])]);if distance<best_distance{best_distance=distance;best_slot=slot}}
				labels[i]=i64(best_slot)
			}
			mut updated:=[4]i64{}
			for slot in 0..k {
				mut first:=n
				for i in 0..n{if labels[i]==i64(slot){first=i;break}}
				if first==n{return invalid_result}
				mut best_index:=first
				mut best_cost:=i64(0)
				for i in 0..n{if labels[i]==i64(slot){best_cost+=distance_i64(points[first],points[i])}}
				for candidate in first+1..n {
					if labels[candidate]!=i64(slot){continue}
					mut cost:=i64(0)
					for i in 0..n{if labels[i]==i64(slot){cost+=distance_i64(points[candidate],points[i])}}
					if cost<best_cost{best_cost=cost;best_index=candidate}
				}
				updated[slot]=i64(best_index)
			}
			mut changed:=false
			for slot in 0..k{if updated[slot]!=medoids[slot]{changed=true}}
			if !changed{break}
			for slot in 0..k{medoids[slot]=updated[slot]}
		}
		mut result:=i64(0)
		for slot in 0..k{result|=medoids[slot]<<(3*slot)}
		for i in 0..n{result|=labels[i]<<(12+2*i)}
		return result
	}
}
