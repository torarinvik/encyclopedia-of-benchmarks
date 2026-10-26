// GNU Go 1.1 provenance: Copyright (C) Free Software Foundation, Inc.
// Written by Man L. Li, modified by Wayne Iba, documented by Bob Webber.
// Upstream suicide/eval/countlib/count are under GNU GPL version 1; derivative under GPLv1.
fn group_liberties(board: &[u8; 361], start: usize, color: u8) -> usize {
    let mut seen=[false;361]; let mut lib_seen=[false;361]; let mut stack=[0usize;361];
    let mut top=1usize; let mut count=0usize; stack[0]=start; seen[start]=true;
    while top>0 { top-=1; let at=stack[top]; let r=at/19; let c=at%19; let mut nb=[0usize;4]; let mut n=0;
        if r>0 { nb[n]=at-19;n+=1; } if r<18 { nb[n]=at+19;n+=1; } if c>0 { nb[n]=at-1;n+=1; } if c<18 { nb[n]=at+1;n+=1; }
        for &next in &nb[..n] { if board[next]==0 { if !lib_seen[next] { lib_seen[next]=true;count+=1; } }
            else if board[next]==color && !seen[next] { seen[next]=true;stack[top]=next;top+=1; } }
    }
    count
}

#[no_mangle]
pub unsafe extern "C" fn prolangs_c_gnugo_suicide(input:*const i64,length:usize)->i64 {
    if input.is_null() || !(6..=246).contains(&length) { return -1; }
    let row=*input;let col=*input.add(1);let own=*input.add(2);let opponent=*input.add(3);let ko=*input.add(4);let count=*input.add(5);
    if !(0..19).contains(&row)||!(0..19).contains(&col)||!(own==1||own==2)||!(opponent==1||opponent==2)||own==opponent||ko < -1||ko>=361||!(0..=120).contains(&count)||length!=6+2*count as usize{return -1;}
    let mut board=[0u8;361];
    for k in 0..count as usize {let at=*input.add(6+2*k);let stone=*input.add(7+2*k);if !(0..361).contains(&at)||!(stone==1||stone==2)||board[at as usize]!=0{return -1;}board[at as usize]=stone as u8;}
    let target=(row*19+col) as usize;if board[target]!=0{return -1;}board[target]=opponent as u8;
    if group_liberties(&board,target,opponent as u8)>0{return 0;}
    let mut dead=0i64;for i in 0..361{if board[i]==own as u8&&group_liberties(&board,i,own as u8)==0{dead+=1;}}
    if dead==0||(dead==1&&ko==target as i64){1}else{0}
}
