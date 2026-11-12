@[export: 'gabow_scc']
pub fn gabow_scc(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input==nil || length<2 || length>4096 { return -1 }
		if input[0]<0 || input[0]>40 || input[1]<0 || input[1]>2047 { return -1 }
		n,m:=int(input[0]),int(input[1])
		if length!=usize(2+2*m) { return -1 }
		mut adjacency:=[40]u64{}
		mut neighbors:=[1600]int{}; mut degree:=[40]int{}
		for e in 0..m {
			source,target:=input[2+2*e],input[3+2*e]
			if source<0 || target<0 || source>=i64(n) || target>=i64(n) { return -1 }
			u,v:=int(source),int(target); bit:=u64(1)<<v
			if adjacency[u]&bit==0 { adjacency[u]|=bit; neighbors[u*40+degree[u]]=v; degree[u]++ }
		}
		mut preorder:=[40]i64{}; mut component:=[40]i64{}
		mut vertices:=[40]int{}; mut boundaries:=[40]int{}; mut dfs:=[40]int{}; mut next_neighbor:=[40]int{}
		for v in 0..n { preorder[v]= -1; component[v]= -1 }
		mut vertex_count:=0; mut boundary_count:=0; mut depth:=0; mut clock:=0; mut component_count:=0
		for root in 0..n {
			if preorder[root]>=0 { continue }
			preorder[root]=i64(clock); clock++
			vertices[vertex_count]=root; vertex_count++
			boundaries[boundary_count]=root; boundary_count++
			dfs[depth]=root; next_neighbor[depth]=0; depth++
			for depth>0 {
				frame:=depth-1; v:=dfs[frame]
				if next_neighbor[frame]<degree[v] {
					w:=neighbors[v*40+next_neighbor[frame]]; next_neighbor[frame]++
					if preorder[w]<0 {
						preorder[w]=i64(clock); clock++
						vertices[vertex_count]=w; vertex_count++
						boundaries[boundary_count]=w; boundary_count++
						dfs[depth]=w; next_neighbor[depth]=0; depth++
					} else if component[w]<0 {
					for boundary_count>0 && preorder[boundaries[boundary_count-1]]>preorder[w] { boundary_count-- }
				}
				} else {
					depth--
					if boundary_count>0 && boundaries[boundary_count-1]==v {
						boundary_count--
						for {
							vertex_count--; member:=vertices[vertex_count]; component[member]=i64(component_count)
							if member==v { break }
						}
						component_count++
					}
				}
			}
		}
		mut staged:=[81]u8{}; mut position:=1; staged[0]=u8(component_count)
		for first in 0..n {
			id:=component[first]; mut seen:=false
			for earlier in 0..first { if component[earlier]==id { seen=true } }
			if seen { continue }
			mut size:=0
			for v in first..n { if component[v]==id { size++ } }
			staged[position]=u8(size); position++
			for v in first..n { if component[v]==id { staged[position]=u8(v); position++ } }
		}
		if output==nil || output_capacity<usize(position) { return -2 }
		for q in 0..position { output[q]=staged[q] }
		return i64(position)
	}
}
