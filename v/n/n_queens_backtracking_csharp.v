module n_queens_backtracking_csharp

const max_n = 8
const max_output_words = 737

fn safe(rows []int, column int, row int) bool {
	for c in 0 .. column { prior:=rows[c]; if prior==row||prior+c==row+column||prior+column==row+c { return false } }
	return true
}
fn enumerate(n int,column int,mut rows []int,mut values []i64,mut used int) {
	if column==n {for c in 0..n {values[used]=i64(rows[c]);used++};values[0]++;return}
	for row in 0..n {if safe(rows,column,row) {rows[column]=row;enumerate(n,column+1,mut rows,mut values,mut used)}}
}
fn put_i64(output &u8,index int,value i64) {bits:=u64(value);unsafe{for b in 0..8{output[index*8+b]=u8((bits>>u64(8*b))&255)}}}

@[export: 'n_queens_backtracking_csharp']
pub fn n_queens_backtracking_csharp(n i64,mut output &u8,capacity usize) i64 {
	if n<0||n>max_n {return -1}
	unsafe {
		mut values:=[]i64{len:max_output_words};mut used:=1
		if n>0 {mut rows:=[max_n]int{};enumerate(int(n),0,mut rows[..],mut values,mut used)}
		needed:=used*8
		if output==nil||capacity<usize(needed) {return -2}
		for i in 0..used {put_i64(output,i,values[i])}
		return i64(needed)
	}
}
