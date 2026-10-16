package push_relabel

import "core:c"

MAX_VERTICES :: 14
AUGMENTED_VERTICES :: 16
MAX_INPUT_LENGTH :: 227
MAX_CAPACITY :: i64(1_000_000)

@(export)
push_relabel :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT_LENGTH do return -1
	n64 := input[0]
	source_count64 := input[1]
	if n64 < 2 || n64 > MAX_VERTICES || source_count64 < 1 || source_count64 >= n64 do return -1
	n := int(n64)
	source_count := int(source_count64)
	sink_count_index := 2 + source_count
	if int(length) <= sink_count_index do return -1

	is_source: [MAX_VERTICES]bool
	is_sink: [MAX_VERTICES]bool
	sources: [MAX_VERTICES]int
	for index:=0; index<source_count; index+=1 {
		node64 := input[2+index]
		if node64<0 || node64>=n64 || is_source[int(node64)] do return -1
		sources[index]=int(node64)
		is_source[int(node64)]=true
	}
	sink_count64 := input[sink_count_index]
	if sink_count64<1 || sink_count64>n64-source_count64 do return -1
	sink_count := int(sink_count64)
	matrix_start := sink_count_index+1+sink_count
	if int(length)<matrix_start || int(length)!=matrix_start+n*n do return -1
	for index:=0; index<sink_count; index+=1 {
		node64 := input[sink_count_index+1+index]
		if node64<0 || node64>=n64 || is_sink[int(node64)] || is_source[int(node64)] do return -1
		is_sink[int(node64)]=true
	}

	residual: [AUGMENTED_VERTICES*AUGMENTED_VERTICES]i64
	source_out: [MAX_VERTICES]i64
	flow_limit:=i64(0)
	for row:=0; row<n; row+=1 {
		for column:=0; column<n; column+=1 {
			capacity:=input[matrix_start+row*n+column]
			if capacity<0 || capacity>MAX_CAPACITY || (row==column && capacity!=0) do return -1
			residual[row*AUGMENTED_VERTICES+column]=capacity
			if is_source[row] {
				source_out[row]+=capacity
				flow_limit+=capacity
			}
		}
	}
	super_source:=n
	super_sink:=n+1
	for index:=0; index<source_count; index+=1 {
		residual[super_source*AUGMENTED_VERTICES+sources[index]]=source_out[sources[index]]
	}
	for index:=0; index<sink_count; index+=1 {
		sink:=int(input[sink_count_index+1+index])
		residual[sink*AUGMENTED_VERTICES+super_sink]=flow_limit
	}

	height: [AUGMENTED_VERTICES]int
	excess: [AUGMENTED_VERTICES]i64
	active: [AUGMENTED_VERTICES]bool
	height[super_source]=n+2
	for index:=0; index<source_count; index+=1 {
		source:=sources[index]
		initial_excess:=residual[super_source*AUGMENTED_VERTICES+source]
		residual[super_source*AUGMENTED_VERTICES+source]=0
		residual[source*AUGMENTED_VERTICES+super_source]+=initial_excess
		excess[source]+=initial_excess
		if excess[source]>0 { active[source]=true }
	}

	for {
		node:=0
		for node<n && !active[node] { node+=1 }
		if node==n { break }
		active[node]=false
		for excess[node]>0 {
			pushed:=false
			for neighbor:=0; neighbor<n+2 && excess[node]>0; neighbor+=1 {
				edge:=node*AUGMENTED_VERTICES+neighbor
				if residual[edge]<=0 || height[node]!=height[neighbor]+1 do continue
				amount:=excess[node]
				if residual[edge]<amount { amount=residual[edge] }
				residual[edge]-=amount
				residual[neighbor*AUGMENTED_VERTICES+node]+=amount
				excess[node]-=amount
				previous_excess:=excess[neighbor]
				excess[neighbor]+=amount
				if neighbor<n && previous_excess==0 { active[neighbor]=true }
				pushed=true
			}
			if excess[node]>0 && !pushed {
				minimum_height:=1000
				for neighbor:=0; neighbor<n+2; neighbor+=1 {
					if residual[node*AUGMENTED_VERTICES+neighbor]>0 && height[neighbor]<minimum_height { minimum_height=height[neighbor] }
				}
				if minimum_height==1000 do return -1
				height[node]=minimum_height+1
			}
		}
	}
	return excess[super_sink]
}
