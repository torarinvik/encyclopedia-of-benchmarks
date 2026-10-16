package crossword_puzzle_solver
import "core:c"

search :: proc "contextless" (grid: ^[64]i64, rows, cols: int,
	words: ^[8][8]i64, lengths, order: ^[8]int, depth, word_count: int) -> bool {
	if depth == word_count do return true
	word := order[depth]
	n := lengths[word]
	for row := 0; row < rows; row += 1 {
		for col := 0; col < cols; col += 1 {
			for direction := 0; direction < 2; direction += 1 {
				vertical := direction == 0
				if (vertical && row+n>rows) || (!vertical && col+n>cols) do continue
				cells: [8]int
			added: [8]bool
			valid := true
			for i := 0; i < n; i += 1 {
				cell := row*cols+col+i
				if vertical do cell = (row+i)*cols+col
				cells[i] = cell
				if grid[cell] != 0 && grid[cell] != words[word][i] do valid = false
			}
			if !valid do continue
			for i := 0; i < n; i += 1 { added[i] = grid[cells[i]] == 0; grid[cells[i]] = words[word][i] }
			if search(grid,rows,cols,words,lengths,order,depth+1,word_count) do return true
			for i := 0; i < n; i += 1 { if added[i] do grid[cells[i]] = 0 }
			}
		}
	}
	return false
}

@(export)
crossword_puzzle_solver :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input==nil || length<3 do return -1
	rv,cv,nv := input[0],input[1],input[2]
	if rv<1 || rv>8 || cv<1 || cv>8 || nv<0 || nv>8 do return -1
	rows,cols,word_count := int(rv),int(cv),int(nv)
	if length<c.size_t(3+rows*cols) do return -1
	grid: [64]i64
	for i:=0;i<rows*cols;i+=1 { value:=input[3+i]; if value!=0 && value!=-1 && (value<65 || value>90) do return -1; grid[i]=value }
	words: [8][8]i64
	lengths,order: [8]int
	pos:=3+rows*cols
	for w:=0;w<word_count;w+=1 {
		if c.size_t(pos)>=length || input[pos]<1 || input[pos]>8 do return -1
		lengths[w]=int(input[pos]); pos+=1
		if c.size_t(lengths[w])>length-c.size_t(pos) do return -1
		for i:=0;i<lengths[w];i+=1 { letter:=input[pos]; pos+=1; if letter<65 || letter>90 do return -1; words[w][i]=letter }
	}
	if c.size_t(pos)!=length do return -1
	for i:=0;i<word_count;i+=1 { order[i]=i }
	for i:=1;i<word_count;i+=1 {
		value:=order[i]; j:=i
		for j>0 && lengths[order[j-1]]<lengths[value] { order[j]=order[j-1]; j-=1 }
		order[j]=value
	}
	solved:=search(&grid,rows,cols,&words,&lengths,&order,0,word_count)
	required:=c.size_t((1+rows*cols)*8)
	if output==nil || capacity<required do return -2
	for i:=0;i<1+rows*cols;i+=1 { value:=i64(0); if i>0 do value=grid[i-1]; if i==0 && solved do value=1; bits:=u64(value); for b:=0;b<8;b+=1 { output[i*8+b]=u8((bits>>u64(b*8))&255) } }
	return i64(required)
}
