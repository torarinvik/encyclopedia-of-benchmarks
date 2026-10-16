package crossword_solver
import "core:c"

search :: proc "contextless" (grid: ^[64]i64, rows, cols: int, words: ^[8][8]i64, lens: ^[8]int, rem: ^[8]int, count: int) -> bool {
	total := rows*cols
	start := 0
	for start < total && grid[start] != 0 { start += 1 }
	if start == total do return true
	row, col := start/cols, start%cols
	current := rem^
	current_count := count
	for wi := 0; wi < count; wi += 1 {
		word, n := rem[wi], lens[rem[wi]]
		for direction := 0; direction < 2; direction += 1 {
			vertical := direction == 0
			if (vertical && row+n>rows) || (!vertical && col+n>cols) do continue
			valid := true
			for i := 0; i < n; i += 1 { cell := (row*cols+col)+i; if vertical do cell = (row+i)*cols+col; if grid[cell] != 0 do valid=false }
			if !valid do continue
			for i := 0; i < n; i += 1 { cell := row*cols+col+i; if vertical do cell = (row+i)*cols+col; grid[cell]=words[word][i] }
			next: [8]int
			next_count, removed := 0, 0
			for i := 0; i < current_count; i += 1 { if current[i]==word { removed=i } else { next[next_count]=current[i]; next_count+=1 } }
			for i := removed+1; i < current_count; i += 1 { current[i-1]=current[i] }
			current_count -= 1
			if search(grid,rows,cols,words,lens,&next,next_count) do return true
			for i := 0; i < n; i += 1 { cell := row*cols+col+i; if vertical do cell = (row+i)*cols+col; grid[cell]=0 }
			current[current_count]=word; current_count+=1
		}
	}
	return false
}

@(export)
crossword_solver :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input==nil || length<3 do return -1
	rv,cv,nv := input[0],input[1],input[2]
	if rv<1 || rv>8 || cv<1 || cv>8 || nv<0 || nv>8 do return -1
	rows,cols,count := int(rv),int(cv),int(nv)
	if length<c.size_t(3+rows*cols) do return -1
	grid: [64]i64
	for i:=0;i<rows*cols;i+=1 { v:=input[3+i]; if v!=0 && v!=-1 && (v<65 || v>90) do return -1; grid[i]=v }
	words: [8][8]i64
	lens: [8]int
	pos:=3+rows*cols
	for w:=0;w<count;w+=1 {
		if c.size_t(pos)>=length || input[pos]<1 || input[pos]>8 do return -1
		lens[w]=int(input[pos]); pos+=1
		if c.size_t(lens[w])>length-c.size_t(pos) do return -1
		for i:=0;i<lens[w];i+=1 { v:=input[pos]; pos+=1; if v<65 || v>90 do return -1; words[w][i]=v }
		for p:=0;p<w;p+=1 { same:=lens[p]==lens[w]; for i:=0;same && i<lens[w];i+=1 { if words[p][i]!=words[w][i] do same=false }; if same do return -1 }
	}
	if c.size_t(pos)!=length do return -1
	rem: [8]int
	for i:=0;i<count;i+=1 { rem[i]=i }
	solved:=search(&grid,rows,cols,&words,&lens,&rem,count)
	required:=c.size_t((1+rows*cols)*8)
	if output==nil || capacity<required do return -2
	for i:=0;i<1+rows*cols;i+=1 { value:=i64(0); if i>0 do value=grid[i-1]; if i==0 && solved do value=1; bits:=u64(value); for b:=0;b<8;b+=1 { output[i*8+b]=u8((bits>>u64(b*8))&255) } }
	return i64(required)
}
