"""Independent reference for the bounded Prolangs-C football tie-break core."""

from __future__ import annotations

from fractions import Fraction

MAX_TEAMS = 8
MAX_RECORD_GAMES = 64
MAX_NET_POINTS = 4096


def prolangs_football_tiebreaks(values: list[int]) -> int:
    """Return tied teams' best-to-worst order as base-32 ID digits, or -2."""
    if not isinstance(values, list) or not values or any(type(v) is not int for v in values):
        return -2
    team_count = values[0]
    if not 2 <= team_count <= MAX_TEAMS:
        return -2
    matrix_size = team_count * team_count
    if len(values) != 1 + 12 * team_count + 2 * matrix_size:
        return -2

    teams: list[tuple[int, ...]] = []
    ids: set[int] = set()
    for team_index in range(team_count):
        start = 1 + 12 * team_index
        team = tuple(values[start : start + 12])
        (team_id, conference, division, div_points, div_games, conf_points,
         conf_games, common_points, common_games, div_net, conf_net, total_net) = team
        if not 0 <= team_id <= 31 or team_id in ids:
            return -2
        ids.add(team_id)
        if conference not in (0, 1) or not 0 <= division <= 2:
            return -2
        for points, games in ((div_points, div_games), (conf_points, conf_games),
                              (common_points, common_games)):
            if not 0 <= games <= MAX_RECORD_GAMES or not 0 <= points <= 2 * games:
                return -2
        if any(abs(net) > MAX_NET_POINTS for net in (div_net, conf_net, total_net)):
            return -2
        teams.append(team)

    wins_start = 1 + 12 * team_count
    ties_start = wins_start + matrix_size
    wins_flat = values[wins_start : wins_start + matrix_size]
    ties_flat = values[ties_start : ties_start + matrix_size]
    wins = [wins_flat[i : i + team_count] for i in range(0, matrix_size, team_count)]
    ties = [ties_flat[i : i + team_count] for i in range(0, matrix_size, team_count)]
    for i in range(team_count):
        if wins[i][i] != 0 or ties[i][i] != 0:
            return -2
        for j in range(team_count):
            if not 0 <= wins[i][j] <= MAX_RECORD_GAMES or not 0 <= ties[i][j] <= MAX_RECORD_GAMES:
                return -2
            if ties[i][j] != ties[j][i]:
                return -2

    def same_division(group: list[int]) -> bool:
        first = teams[group[0]]
        return all(teams[index][1:3] == first[1:3] for index in group[1:])

    def h2h_score(index: int, group: list[int]) -> Fraction:
        won = sum(wins[index][other] for other in group if other != index)
        lost = sum(wins[other][index] for other in group if other != index)
        tied = sum(ties[index][other] for other in group if other != index)
        games = won + lost + tied
        return Fraction(2 * won + tied, 2 * games) if games else Fraction(0, 1)

    def record_score(index: int, points_field: int, games_field: int) -> Fraction:
        team = teams[index]
        games = team[games_field]
        return Fraction(team[points_field], 2 * games) if games else Fraction(0, 1)

    def split_by_score(group: list[int], score, next_stage: int) -> list[int]:
        ordered = sorted(group, key=score, reverse=True)
        parts: list[list[int]] = []
        for index in ordered:
            if not parts or score(parts[-1][0]) != score(index):
                parts.append([index])
            else:
                parts[-1].append(index)
        if len(parts) == 1:
            return resolve(group, next_stage)
        return [index for part in parts for index in resolve(part, 0)]

    def sweep_split(group: list[int]) -> tuple[list[int], list[int]] | None:
        for position, index in enumerate(group):
            sweeps_win = True
            sweeps_lose = True
            for other in group:
                if other == index:
                    continue
                won = wins[index][other]
                lost = wins[other][index]
                tied = ties[index][other]
                if won + lost + tied == 0 or tied != 0:
                    sweeps_win = sweeps_lose = False
                if lost != 0:
                    sweeps_win = False
                if won != 0:
                    sweeps_lose = False
            if sweeps_win:
                reordered = list(group)
                reordered[0], reordered[position] = reordered[position], reordered[0]
                return [reordered[0]], reordered[1:]
            if sweeps_lose:
                reordered = list(group)
                last = len(reordered) - 1
                reordered[last], reordered[position] = reordered[position], reordered[last]
                return reordered[:last], [reordered[last]]
        return None

    def resolve(group: list[int], stage: int) -> list[int]:
        if len(group) <= 1 or stage >= 6:
            return list(group)
        same_div = same_division(group)
        if stage == 0:
            if same_div or len(group) == 2:
                return split_by_score(group, lambda i: h2h_score(i, group), 1)
            split = sweep_split(group)
            if split is not None:
                best, rest = split
                return resolve(best, 0) + resolve(rest, 0)
            return resolve(group, 1)
        if stage == 1:
            if not same_div:
                return resolve(group, 2)
            return split_by_score(group, lambda i: record_score(i, 3, 4), 2)
        if stage == 2:
            return split_by_score(group, lambda i: record_score(i, 5, 6), 3)
        if stage == 3:
            if any(teams[i][8] < 4 for i in group):
                return resolve(group, 4)
            return split_by_score(group, lambda i: record_score(i, 7, 8), 4)
        if stage == 4:
            field = 9 if same_div else 10
            return split_by_score(group, lambda i: Fraction(teams[i][field], 1), 5)
        return split_by_score(group, lambda i: Fraction(teams[i][11], 1), 6)

    # The source has sorted each tied block before break_a_tie, with
    # conference preceding team_id. Recursive splits restart at head-to-head.
    order = resolve(sorted(range(team_count), key=lambda i: (teams[i][1], teams[i][0])), 0)
    packed = 0
    for index in order:
        packed = packed * 32 + teams[index][0]
    return packed
