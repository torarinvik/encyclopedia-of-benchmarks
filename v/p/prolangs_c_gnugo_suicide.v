module prolangs_c_gnugo_suicide

// GNU Go 1.1 provenance: Copyright (C) Free Software Foundation, Inc.
// Written by Man L. Li, modified by Wayne Iba, documented by Bob Webber.
// Upstream suicide/eval/countlib/count are under GNU GPL version 1; derivative under GPLv1.
fn group_liberties(board [361]u8, start int, color u8) int {
	mut seen := [361]bool{}
	mut lib_seen := [361]bool{}
	mut stack := [361]int{}
	mut top := 1; mut total := 0; stack[0] = start; seen[start] = true
	for top > 0 {
		top--; at := stack[top]; r, c := at/19, at%19
		mut nb := [4]int{}; mut n := 0
		if r > 0 { nb[n] = at-19; n++ }; if r < 18 { nb[n] = at+19; n++ }
		if c > 0 { nb[n] = at-1; n++ }; if c < 18 { nb[n] = at+1; n++ }
		for j := 0; j < n; j++ { next := nb[j]
			if board[next] == 0 { if !lib_seen[next] { lib_seen[next] = true; total++ } }
			else if board[next] == color && !seen[next] { seen[next] = true; stack[top] = next; top++ }
		}
	}
	return total
}

@[export: 'prolangs_c_gnugo_suicide']
pub fn prolangs_c_gnugo_suicide(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 6 || length > 246 { return -1 }
		row,col,own,opponent,ko,count := input[0],input[1],input[2],input[3],input[4],input[5]
		if row<0 || row>=19 || col<0 || col>=19 || (own!=1 && own!=2) || (opponent!=1 && opponent!=2) || own==opponent || ko < -1 || ko>=361 || count<0 || count>120 || length!=usize(6+2*count) { return -1 }
		mut board := [361]u8{}
		for k:=0;k<int(count);k++ { at,stone:=input[6+2*k],input[7+2*k]
			if at<0 || at>=361 || (stone!=1 && stone!=2) || board[int(at)]!=0 { return -1 }
			board[int(at)]=u8(stone)
		}
		target:=int(row*19+col);if board[target]!=0{return -1};board[target]=u8(opponent)
		if group_liberties(board,target,u8(opponent))>0{return 0}
		mut dead:=i64(0)
		for i:=0;i<361;i++{if board[i]==u8(own)&&group_liberties(board,i,u8(own))==0{dead++}}
		if dead==0||(dead==1&&ko==i64(target)){return 1};return 0
	}
}
