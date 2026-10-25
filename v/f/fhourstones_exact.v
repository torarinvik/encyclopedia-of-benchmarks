/*
Fhourstones 2.0 copyright and distribution notice:
This software is copyright (c) 1996 by John Tromp, Lindenlaan 33,
1701 GT Heerhugowaard, Netherlands. E-mail: tromp@cwi.nl.
This notice must not be removed. This software must not be sold for profit.
You may redistribute if your distributees have the same rights and restrictions.

Fhourstones 3.1 copyright and distribution notice:
This software is copyright (c) 1996-2005 by John Tromp, Insulindeweg 908,
1095 DX Amsterdam, Netherlands. E-mail: tromp@cwi.nl.
This notice must not be removed. This software must not be sold for profit.
You may redistribute if your distributees have the same rights and restrictions.
*/
module main

const width = 7
const height = 6
const board_cells = 42
const min_moves = 36
const max_moves = 41
const move_order = [7]int{3, 2, 4, 1, 5, 0, 6}
const dir_x = [4]int{1, 0, 1, 1}
const dir_y = [4]int{0, 1, 1, -1}

fn wins_at(board [42]i8, column int, row int, side i8) bool {
    for direction in 0..4 {
        mut count := 1
        for sign_index in 0..2 {
            sign := if sign_index == 0 { -1 } else { 1 }
            for step in 1..4 {
                x := column + sign * step * dir_x[direction]
                y := row + sign * step * dir_y[direction]
                if x < 0 || x >= width || y < 0 || y >= height { break }
                if board[y * width + x] != side { break }
                count++
            }
        }
        if count >= 4 { return true }
    }
    return false
}

fn solve_endgame(mut board [42]i8, mut heights [7]int, side i8, remaining int,
    alpha_in int, beta int) int {
    if remaining == 0 { return 0 }
    mut alpha := alpha_in
    mut best := -3
    for index in 0..width {
        column := move_order[index]
        row := heights[column]
        if row == height { continue }
        board[row * width + column] = side
        heights[column] = row + 1
        value := if wins_at(board, column, row, side) { 2 } else {
            -solve_endgame(mut board, mut heights, if side == 1 { i8(2) } else { i8(1) }, remaining - 1, -beta, -alpha)
        }
        heights[column] = row
        board[row * width + column] = 0
        if value > best { best = value }
        if value > alpha { alpha = value }
        if alpha >= beta { break }
    }
    return best
}

pub fn fhourstones_exact(input &i64, length usize) i64 {
    if unsafe { input == nil } || length < 2 || length > 42 { return -1 }
    count_value := unsafe { input[0] }
    if count_value < min_moves || count_value > max_moves { return -1 }
    count := int(count_value)
    if length != usize(count + 1) { return -1 }
    mut board := [42]i8{}
    mut heights := [7]int{}
    for turn in 0..count {
        column_value := unsafe { input[turn + 1] }
        if column_value < 0 || column_value >= width { return -1 }
        column := int(column_value)
        row := heights[column]
        if row >= height { return -1 }
        side := if turn % 2 == 0 { i8(1) } else { i8(2) }
        board[row * width + column] = side
        heights[column] = row + 1
        if wins_at(board, column, row, side) { return -1 }
    }
    side := if count % 2 == 0 { i8(1) } else { i8(2) }
    return i64(solve_endgame(mut board, mut heights, side, board_cells - count, -3, 3))
}
