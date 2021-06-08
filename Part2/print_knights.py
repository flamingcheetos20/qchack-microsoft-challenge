N = 2
B = 4 * N + 5
board = [[None for _ in range(B)] for _ in range(B)]
for r in range(B):
    row = ""
    for c in range(B):
        if r % (N + 1) == 0:
            if c % (N + 1) > 0:
                board[r][c] = "-"
                row += "-"
            else:
                board[r][c] = "+"
                row += "+"
        else:
            if c % (N + 1) == 0:
                board[r][c] = "|"
                row += "|"
            else:
                if r // (N + 1) == 3 and c // (N + 1) == 0:
                    board[r][c] = "N"
                    row += "N"
                else:
                    board[r][c] = " "
                    row += " "

    # print(board[r])
    print(row)
