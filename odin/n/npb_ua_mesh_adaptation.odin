package npb_ua_mesh_adaptation

import "core:c"

DEPTH :: 2
SIDE :: 4
MAX_CELLS :: 64
INVALID_RESULT :: -1.0e300

Cell :: struct { level, x, y, z: int }

cell_size :: proc(cell: Cell) -> int { return 1 << (DEPTH - cell.level) }
abs_i :: proc(value: int) -> int { return if value < 0 then -value else value }

overlaps_source :: proc(cell: Cell, sx, sy, sz, radius: int) -> bool {
	point := [3]int{sx, sy, sz}
	lower := [3]int{cell.x, cell.y, cell.z}
	size := cell_size(cell)
	squared := 0
	for axis := 0; axis < 3; axis += 1 {
		distance := 0
		if point[axis] < lower[axis] { distance = lower[axis] - point[axis] }
		else if point[axis] > lower[axis] + size { distance = point[axis] - lower[axis] - size }
		squared += distance * distance
	}
	return squared < radius * radius
}

neighboring :: proc(a, b: Cell) -> bool {
	alo := [3]int{a.x, a.y, a.z}
	blo := [3]int{b.x, b.y, b.z}
	asize, bsize := cell_size(a), cell_size(b)
	touching := 0
	for axis := 0; axis < 3; axis += 1 {
		ahi, bhi := alo[axis] + asize, blo[axis] + bsize
		if ahi == blo[axis] || bhi == alo[axis] { touching += 1 }
		else if ahi <= blo[axis] || bhi <= alo[axis] { return false }
	}
	return touching == 1 || touching == 2
}

split_cell :: proc(cells: [^]Cell, count: ^int, index: int) -> bool {
	parent := cells[index]
	if parent.level >= DEPTH || count^ + 7 > MAX_CELLS do return false
	child_size := cell_size(parent) / 2
	i := count^
	for i > index + 1 { i -= 1; cells[i + 7] = cells[i] }
	slot := index
	for bz := 0; bz < 2; bz += 1 { for by := 0; by < 2; by += 1 { for bx := 0; bx < 2; bx += 1 {
		cells[slot] = Cell{parent.level + 1, parent.x + bx*child_size, parent.y + by*child_size, parent.z + bz*child_size}
		slot += 1
	}}}
	count^ += 7
	return true
}

balanced :: proc(cells: [^]Cell, count: int) -> bool {
	for i := 0; i < count; i += 1 { for j := i + 1; j < count; j += 1 {
		if neighboring(cells[i], cells[j]) && abs_i(cells[i].level-cells[j].level) > 1 do return false
	}}
	return true
}

balance_mesh :: proc(cells: [^]Cell, count: ^int) -> bool {
	for {
		coarse := -1
		for i := 0; i < count^ && coarse < 0; i += 1 { for j := i + 1; j < count^; j += 1 {
			if neighboring(cells[i], cells[j]) && abs_i(cells[i].level-cells[j].level) > 1 {
				coarse = if cells[i].level < cells[j].level then i else j
				break
			}
		}}
		if coarse < 0 do return true
		if !split_cell(cells, count, coarse) do return false
	}
}

is_child :: proc(cell: Cell, level, x, y, z, size: int) -> bool {
	return cell.level == level && cell.x >= x && cell.x < x+size && cell.y >= y && cell.y < y+size && cell.z >= z && cell.z < z+size
}

coarsen_once :: proc(cells: [^]Cell, count: ^int, sx, sy, sz, radius: int) -> bool {
	for seed := 0; seed < count^; seed += 1 {
		child := cells[seed]
		if child.level == 0 do continue
		parent_level := child.level - 1
		parent_size := 1 << (DEPTH-parent_level)
		child_size := parent_size/2
		px, py, pz := child.x/parent_size*parent_size, child.y/parent_size*parent_size, child.z/parent_size*parent_size
		parent := Cell{parent_level,px,py,pz}
		if overlaps_source(parent,sx,sy,sz,radius) do continue
		found: [8]int
		for q := 0; q < 8; q += 1 { found[q] = -1 }
		for i := 0; i < count^; i += 1 { if is_child(cells[i],child.level,px,py,pz,parent_size) {
			bx,by,bz := (cells[i].x-px)/child_size,(cells[i].y-py)/child_size,(cells[i].z-pz)/child_size
			found[bx+2*by+4*bz] = i
		}}
		complete := true
		for q := 0; q < 8; q += 1 { if found[q] < 0 { complete = false } }
		if !complete do continue
		safe := true
		for i := 0; i < count^; i += 1 {
			sibling := false
			for q := 0; q < 8; q += 1 { if found[q] == i { sibling = true } }
			if !sibling && neighboring(parent,cells[i]) && abs_i(parent_level-cells[i].level)>1 { safe=false }
		}
		if !safe do continue
		compact: [MAX_CELLS]Cell
		compact_count := 0
		inserted := false
		for i := 0; i < count^; i += 1 {
			sibling := false
			for q := 0; q < 8; q += 1 { if found[q] == i { sibling=true } }
			if !sibling { compact[compact_count]=cells[i]; compact_count += 1 }
			else if !inserted { compact[compact_count]=parent; compact_count += 1; inserted=true }
		}
		for i := 0; i < compact_count; i += 1 { cells[i]=compact[i] }
		count^ = compact_count
		return true
	}
	return false
}

less_cell :: proc(a,b:Cell)->bool {
	if a.level!=b.level do return a.level<b.level
	if a.z!=b.z do return a.z<b.z
	if a.y!=b.y do return a.y<b.y
	return a.x<b.x
}

@(export)
npb_ua_mesh_adaptation :: proc "c" (input: [^]i64, length: c.size_t) -> f64 {
	if input == nil || length < 9 || length > c.size_t(261) do return INVALID_RESULT
	for q := 0; q < 3; q += 1 { if input[q]<0 || input[q]>SIDE do return INVALID_RESULT }
	if input[3]<1 || input[3]>SIDE || input[4]<1 || input[4]>MAX_CELLS do return INVALID_RESULT
	sx,sy,sz,radius := int(input[0]),int(input[1]),int(input[2]),int(input[3])
	count:=int(input[4]); if length!=c.size_t(5+4*count) do return INVALID_RESULT
	cells:[MAX_CELLS]Cell
	covered:[MAX_CELLS]bool
	for i:=0;i<count;i+=1 {
		lr,xr,yr,zr:=input[5+4*i],input[6+4*i],input[7+4*i],input[8+4*i]
		if lr<0 || lr>DEPTH || xr<0 || xr>SIDE || yr<0 || yr>SIDE || zr<0 || zr>SIDE do return INVALID_RESULT
		cell:=Cell{int(lr),int(xr),int(yr),int(zr)}; size:=cell_size(cell)
		if cell.x+size>SIDE || cell.y+size>SIDE || cell.z+size>SIDE || cell.x%size!=0 || cell.y%size!=0 || cell.z%size!=0 do return INVALID_RESULT
		cells[i]=cell
		for z:=cell.z;z<cell.z+size;z+=1 { for y:=cell.y;y<cell.y+size;y+=1 { for x:=cell.x;x<cell.x+size;x+=1 {
			q:=x+SIDE*(y+SIDE*z);if covered[q] do return INVALID_RESULT;covered[q]=true
		}}}
	}
	for q:=0;q<MAX_CELLS;q+=1 { if !covered[q] do return INVALID_RESULT }
	if !balanced(&cells[0],count) do return INVALID_RESULT
	i:=0
	for i<count {
		if cells[i].level<DEPTH && overlaps_source(cells[i],sx,sy,sz,radius) { if !split_cell(&cells[0],&count,i) do return INVALID_RESULT }
		else { i+=1 }
	}
	if !balance_mesh(&cells[0],&count) do return INVALID_RESULT
	for coarsen_once(&cells[0],&count,sx,sy,sz,radius) {}
	if !balance_mesh(&cells[0],&count) do return INVALID_RESULT
	for i:=1;i<count;i+=1 { key:=cells[i];j:=i;for j>0 && less_cell(key,cells[j-1]) {cells[j]=cells[j-1];j-=1};cells[j]=key }
	checksum:=f64(0)
	for q:=0;q<count;q+=1 { code:=cells[q].level*1000+cells[q].x*100+cells[q].y*10+cells[q].z;checksum+=f64(q+1)*f64(code) }
	return checksum
}
