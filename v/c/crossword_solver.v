module crossword_solver

fn search(mut grid &i64, rows int, cols int, words &i64, lens &i64, mut remaining []int) bool {
	total := rows * cols
	mut start := 0
	for start < total && unsafe { grid[start] } != 0 { start++ }
	if start == total { return true }
	row, col := start / cols, start % cols
	choices := remaining.clone()
	for word in choices {
			n := unsafe { int(lens[word]) }
		for direction in 0 .. 2 {
			vertical := direction == 0
			if (vertical && row + n > rows) || (!vertical && col + n > cols) { continue }
			mut valid := true
			for i in 0 .. n { cell := if vertical { (row+i)*cols+col } else { row*cols+col+i }; if unsafe { grid[cell] } != 0 { valid=false } }
			if !valid { continue }
			for i in 0 .. n { cell := if vertical { (row+i)*cols+col } else { row*cols+col+i }; unsafe { grid[cell]=words[word*8+i] } }
			index := remaining.index(word)
			remaining.delete(index)
			if search(mut grid,rows,cols,words,lens,mut remaining) { return true }
			remaining << word
			for i in 0 .. n { cell := if vertical { (row+i)*cols+col } else { row*cols+col+i }; unsafe { grid[cell]=0 } }
		}
	}
	return false
}

@[export: 'crossword_solver']
pub fn crossword_solver(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 3 { return -1 }
	unsafe {
		rv, cv, nv := input[0], input[1], input[2]
		if rv<1 || rv>8 || cv<1 || cv>8 || nv<0 || nv>8 { return -1 }
		rows, cols, count := int(rv),int(cv),int(nv)
		if length < usize(3+rows*cols) { return -1 }
		mut grid := [64]i64{}
		for i in 0 .. rows*cols { v:=input[3+i]; if v!=0 && v!=-1 && (v<65 || v>90) { return -1 }; grid[i]=v }
		mut words := [64]i64{}
		mut lens := [8]i64{}
		mut pos := 3+rows*cols
		for w in 0 .. count {
			if usize(pos)>=length || input[pos]<1 || input[pos]>8 { return -1 }
			lens[w]=input[pos]; pos++
			if usize(lens[w])>length-usize(pos) { return -1 }
			for i in 0 .. int(lens[w]) { v:=input[pos]; pos++; if v<65 || v>90 { return -1 }; words[w*8+i]=v }
			for p in 0 .. w { mut same:=lens[p]==lens[w]; for i in 0 .. int(lens[w]) { if words[p*8+i]!=words[w*8+i] { same=false } }; if same { return -1 } }
		}
		if usize(pos)!=length { return -1 }
		mut remaining := []int{cap: 8}
		for i in 0 .. count { remaining << i }
		solved:=search(mut grid[0],rows,cols,words[0],lens[0],mut remaining)
		required:=(1+rows*cols)*8
		if output==nil || output_capacity<usize(required) { return -2 }
		for i in 0 .. 1+rows*cols { value:=i64(0); if i>0 { value=grid[i-1] }; if i==0 && solved { value=1 }; bits:=u64(value); for b in 0 .. 8 { output[i*8+b]=u8((bits>>(b*8))&255) } }
		return i64(required)
	}
}
