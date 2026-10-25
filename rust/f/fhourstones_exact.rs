/*
Fhourstones 2.0 copyright and distribution notice:
This software is copyright (c) 1996 by
     John Tromp
     Lindenlaan 33
     1701 GT Heerhugowaard
     Netherlands
E-mail: tromp@cwi.nl
This notice must not be removed.
This software must not be sold for profit.
You may redistribute if your distributees have the
same rights and restrictions.

Fhourstones 3.1 copyright and distribution notice:
This software is copyright (c) 1996-2005 by
     John Tromp
     Insulindeweg 908
     1095 DX Amsterdam
     Netherlands
E-mail: tromp@cwi.nl
This notice must not be removed.
This software must not be sold for profit.
You may redistribute if your distributees have the
same rights and restrictions.
*/

const WIDTH: usize = 7;
const HEIGHT: usize = 6;
const BOARD_CELLS: usize = 42;
const MIN_MOVES: i64 = 36;
const MAX_MOVES: i64 = 41;
const MOVE_ORDER: [usize; WIDTH] = [3, 2, 4, 1, 5, 0, 6];
const DIRECTIONS: [(i32, i32); 4] = [(1, 0), (0, 1), (1, 1), (1, -1)];

fn wins_at(board: &[i8; BOARD_CELLS], column: i32, row: i32, side: i8) -> bool {
    for (dx, dy) in DIRECTIONS {
        let mut count = 1;
        for sign in [-1, 1] {
            for distance in 1..4 {
                let x = column + sign * distance * dx;
                let y = row + sign * distance * dy;
                if x < 0 || x >= WIDTH as i32 || y < 0 || y >= HEIGHT as i32 {
                    break;
                }
                if board[y as usize * WIDTH + x as usize] != side {
                    break;
                }
                count += 1;
            }
        }
        if count >= 4 {
            return true;
        }
    }
    false
}

fn solve_endgame(
    board: &mut [i8; BOARD_CELLS],
    heights: &mut [usize; WIDTH],
    side: i8,
    remaining: usize,
    mut alpha: i32,
    beta: i32,
) -> i32 {
    if remaining == 0 {
        return 0;
    }
    let mut best = -3;
    for column in MOVE_ORDER {
        let row = heights[column];
        if row == HEIGHT {
            continue;
        }
        board[row * WIDTH + column] = side;
        heights[column] = row + 1;
        let value = if wins_at(board, column as i32, row as i32, side) {
            2
        } else {
            -solve_endgame(board, heights, if side == 1 { 2 } else { 1 }, remaining - 1, -beta, -alpha)
        };
        heights[column] = row;
        board[row * WIDTH + column] = 0;
        if value > best {
            best = value;
        }
        if value > alpha {
            alpha = value;
        }
        if alpha >= beta {
            break;
        }
    }
    best
}

#[no_mangle]
pub unsafe extern "C" fn fhourstones_exact(input: *const i64, input_length: usize) -> i64 {
    if input.is_null() || !(2..=42).contains(&input_length) {
        return -1;
    }
    let count_value = *input;
    if !(MIN_MOVES..=MAX_MOVES).contains(&count_value) {
        return -1;
    }
    let count = count_value as usize;
    if input_length != count + 1 {
        return -1;
    }

    let mut board = [0i8; BOARD_CELLS];
    let mut heights = [0usize; WIDTH];
    for turn in 0..count {
        let column_value = *input.add(turn + 1);
        if !(0..WIDTH as i64).contains(&column_value) {
            return -1;
        }
        let column = column_value as usize;
        let row = heights[column];
        if row == HEIGHT {
            return -1;
        }
        let side = if turn % 2 == 0 { 1 } else { 2 };
        board[row * WIDTH + column] = side;
        heights[column] = row + 1;
        if wins_at(&board, column as i32, row as i32, side) {
            return -1;
        }
    }

    let side = if count % 2 == 0 { 1 } else { 2 };
    solve_endgame(&mut board, &mut heights, side, BOARD_CELLS - count, -3, 3) as i64
}
