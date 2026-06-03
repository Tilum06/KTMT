# Battleship - MARS MIPS
# CO2008 Computer Architecture Lab
# 7x7 board, 2 players
# Fleet for each player: 3 ships of length 2, 2 ships of length 3, 1 ship of length 4
#
# Notes:
# - This implementation focuses on correctness and clarity for the assignment/report.
# - Input format for ship placement: row_bow col_bow row_stern col_stern
# - Only horizontal or vertical ships are accepted.
# - Ships cannot overlap.
# - During attack phase, repeated shots are rejected.
# - HIT/MISS are announced. Game ends when one board has no remaining 1s.
#
# Tested design target: MARS syscalls for integer/string I/O.

.data
newline:                .asciiz "\n"
spaceStr:               .asciiz " "
sepLine:                .asciiz "----------------------------------------\n"
#msgTitle:               .asciiz "BATTLESHIP - MIPS (7x7)\n"
msgSetup:               .asciiz "=== SETUP PHASE ===\n"
msgBattle:              .asciiz "=== BATTLE PHASE ===\n"
msgP1Turn:              .asciiz "\n[PLAYER 1 TURN]\n"
msgP2Turn:              .asciiz "\n[PLAYER 2 TURN]\n"
msgPlaceP1:             .asciiz "\nPLAYER 1 - place ships\n"
msgPlaceP2:             .asciiz "\nPLAYER 2 - place ships\n"
msgLen2:                .asciiz "Enter ship of length 2 (row_bow col_bow row_stern col_stern): "
msgLen3:                .asciiz "Enter ship of length 3 (row_bow col_bow row_stern col_stern): "
msgLen4:                .asciiz "Enter ship of length 4 (row_bow col_bow row_stern col_stern): "
msgInvalidShip:         .asciiz "Invalid ship. Re-enter.\n"
msgShipPlaced:          .asciiz "Ship placed successfully.\n"
msgAttackPrompt:        .asciiz "Enter target (row col): "
msgInvalidAttack:       .asciiz "Invalid target. Re-enter.\n"
msgRepeatedAttack:      .asciiz "This cell was already targeted. Choose another.\n"
msgHit:                 .asciiz "HIT!\n"
msgMiss:                .asciiz "MISS!\n"
msgP1Win:               .asciiz "\nPLAYER 1 WINS!\n"
msgP2Win:               .asciiz "\nPLAYER 2 WINS!\n"
msgEnterHidden:         .asciiz "(Press Enter and give control to the other player)\n"

msgMenuTitle:           .asciiz "=== BATTLESHIP ==="
msgMenuOption1:         .asciiz "1. Play Game"
msgMenuOption2:         .asciiz "2. Instructions"
msgMenuOption3:         .asciiz "3. Quit"
msgMenuOption0:         .asciiz "Enter your choice (1, 2 or 3): "
msgMenuInvalid:         .asciiz "Invalid choice. Enter 1, 2 or 3.\n"
msgModeTitle:           .asciiz "\nChoose game mode"
msgModeOption1:         .asciiz "1. One Player (vs Computer)"
msgModeOption2:         .asciiz "2. Two Players"
msgModePrompt:          .asciiz "Enter mode (1 or 2): "
msgModeInvalid:         .asciiz "Invalid mode. Enter 1 or 2.\n"
msgComputerSetup:       .asciiz "\nCOMPUTER - ships placed automatically\n"
msgComputerTurn:        .asciiz "Computer is attacking...\n"
msgHelpHeader:          .asciiz "\n=== HOW TO PLAY ==="
msgHelpLine1:           .asciiz "Fleet: 3 ships of length 2, 2 ships of length 3, 1 ship of length 4"
msgHelpLine2:           .asciiz "Setup: Place your ships on a 7x7 board (rows 0-6, cols 0-6)"
msgHelpLine3:           .asciiz "Format: row_bow col_bow row_stern col_stern (horizontal or vertical)"
msgHelpLine4:           .asciiz "Battle: Attack opponent's board by entering target coordinates (row col)"
msgHelpLine5:           .asciiz "HIT: Opponent has a ship on that cell"
msgHelpLine6:           .asciiz "MISS: Opponent has no ship on that cell"
msgHelpLine7:           .asciiz "Win: Destroy all opponent's ships to win!"
msgHelpFooter:          .asciiz "\n(Press Enter to return...)"

msgRowHeader:           .asciiz "   0 1 2 3 4 5 6\n"
msgDualTitle:           .asciiz "Your board           Enemy map\n"
msgColon:               .asciiz ": "
midGap:                 .asciiz "    "

msgZero:                .asciiz "0"
msgOne:                 .asciiz "1"
msgDot:                 .asciiz "."
msgX:                   .asciiz "X"
msgO:                   .asciiz "O"

inputBuffer:            .space 64


# Boards: 49 integers each
# boardP1, boardP2: own boards, 0=empty or destroyed, 1=ship intact
# memP1, memP2: target memory, 0=unknown, 1=miss, 2=hit
.align 2
boardP1:                .space 196
boardP2:                .space 196
memP1:                  .space 196
memP2:                  .space 196
gameMode:               .word 2
autoBoardTemplate:
                        .word 1,1,0,0,0,0,0
                        .word 1,1,0,0,0,0,0
                        .word 1,1,0,0,0,0,0
                        .word 1,1,1,0,0,0,0
                        .word 1,1,1,0,0,0,0
                        .word 1,1,1,1,0,0,0
                        .word 0,0,0,0,0,0,0

.text
.globl main

main:
    jal show_menu
    beqz $v0, main_play

    li $t0, 1
    beq $v0, $t0, main_help
    j program_end

main_help:
    jal show_help
    j main
    
main_play:
#    la $a0, msgTitle
#    li $v0, 4
#    syscall
    la $a0, sepLine
    li $v0, 4
    syscall

    jal choose_game_mode
    la $t0, gameMode
    sw $v0, 0($t0)

    # init all boards/memories to 0
    la $a0, boardP1
    jal clear_board
    la $a0, boardP2
    jal clear_board
    la $a0, memP1
    jal clear_board
    la $a0, memP2
    jal clear_board

    la $a0, msgSetup
    li $v0, 4
    syscall

    # Player 1 setup
    la $a0, msgPlaceP1
    li $v0, 4
    syscall
    la $a0, boardP1
    jal setup_player

    la $t0, gameMode
    lw $t1, 0($t0)
    li $t2, 1
    beq $t1, $t2, setup_computer

    jal pause_for_swap

    # Player 2 setup
    la $a0, msgPlaceP2
    li $v0, 4
    syscall
    la $a0, boardP2
    jal setup_player

    jal pause_for_swap
    j setup_done

setup_computer:
    la $a0, msgComputerSetup
    li $v0, 4
    syscall
    la $a0, boardP2
    jal load_auto_board

setup_done:

    la $a0, msgBattle
    li $v0, 4
    syscall

game_loop:
    # ------------------ Player 1 turn ------------------
    la $a0, msgP1Turn
    li $v0, 4
    syscall

    la $a0, boardP1
    la $a1, memP2
    la $a2, memP1
    jal print_dual_boards

p1_attack_retry:
    la $a0, msgAttackPrompt
    li $v0, 4
    syscall

    la $a0, inputBuffer
    li $a1, 64
    li $v0, 8
    syscall

    la $a0, inputBuffer
    jal parse_two_ints
    beqz $v0, p1_attack_invalid

    move $s0, $t0          # row
    move $s1, $t1          # col

    # validate 0..6
    bltz $s0, p1_attack_invalid
    bltz $s1, p1_attack_invalid
    li $t0, 7
    bge $s0, $t0, p1_attack_invalid
    bge $s1, $t0, p1_attack_invalid

    # idx = row*7 + col
    li $t0, 7
    mul $t1, $s0, $t0
    add $t1, $t1, $s1
    sll $t2, $t1, 2

    la $t3, memP1
    add $t3, $t3, $t2
    lw $t4, 0($t3)
    bnez $t4, p1_attack_repeat

    la $t5, boardP2
    add $t5, $t5, $t2
    lw $t6, 0($t5)
    beqz $t6, p1_miss

    # hit
    sw $zero, 0($t5)       # destroy cell on opponent board
    li $t7, 2
    sw $t7, 0($t3)
    la $a0, msgHit
    li $v0, 4
    syscall
    j p1_check_win

p1_miss:
    li $t7, 1
    sw $t7, 0($t3)
    la $a0, msgMiss
    li $v0, 4
    syscall
    j p1_check_win

p1_attack_invalid:
    la $a0, msgInvalidAttack
    li $v0, 4
    syscall
    j p1_attack_retry

p1_attack_repeat:
    la $a0, msgRepeatedAttack
    li $v0, 4
    syscall
    j p1_attack_retry

p1_check_win:
    la $a0, boardP2
    jal board_has_ship
    beqz $v0, player1_win

    la $t0, gameMode
    lw $t1, 0($t0)
    li $t2, 1
    beq $t1, $t2, p2_auto_turn

    jal pause_for_swap

    # ------------------ Player 2 turn ------------------
    la $a0, msgP2Turn
    li $v0, 4
    syscall

    la $a0, boardP2
    la $a1, memP1
    la $a2, memP2
    jal print_dual_boards
    
p2_attack_retry:
    la $a0, msgAttackPrompt
    li $v0, 4
    syscall

    la $a0, inputBuffer
    li $a1, 64
    li $v0, 8
    syscall

    la $a0, inputBuffer
    jal parse_two_ints
    beqz $v0, p2_attack_invalid

    move $s0, $t0
    move $s1, $t1

    bltz $s0, p2_attack_invalid
    bltz $s1, p2_attack_invalid
    li $t0, 7
    bge $s0, $t0, p2_attack_invalid
    bge $s1, $t0, p2_attack_invalid

    li $t0, 7
    mul $t1, $s0, $t0
    add $t1, $t1, $s1
    sll $t2, $t1, 2

    la $t3, memP2
    add $t3, $t3, $t2
    lw $t4, 0($t3)
    bnez $t4, p2_attack_repeat

    la $t5, boardP1
    add $t5, $t5, $t2
    lw $t6, 0($t5)
    beqz $t6, p2_miss

    sw $zero, 0($t5)
    li $t7, 2
    sw $t7, 0($t3)
    la $a0, msgHit
    li $v0, 4
    syscall
    j p2_check_win

p2_miss:
    li $t7, 1
    sw $t7, 0($t3)
    la $a0, msgMiss
    li $v0, 4
    syscall
    j p2_check_win

p2_attack_invalid:
    la $a0, msgInvalidAttack
    li $v0, 4
    syscall
    j p2_attack_retry

p2_attack_repeat:
    la $a0, msgRepeatedAttack
    li $v0, 4
    syscall
    j p2_attack_retry

p2_check_win:
    la $a0, boardP1
    jal board_has_ship
    beqz $v0, player2_win

    la $t0, gameMode
    lw $t1, 0($t0)
    li $t2, 1
    beq $t1, $t2, p2_skip_swap

    jal pause_for_swap
p2_skip_swap:
    j game_loop

p2_auto_turn:
    la $a0, msgP2Turn
    li $v0, 4
    syscall

    la $a0, msgComputerTurn
    li $v0, 4
    syscall

    jal computer_attack
    j p2_check_win

player1_win:
    la $a0, msgP1Win
    li $v0, 4
    syscall
    j main

player2_win:
    la $a0, msgP2Win
    li $v0, 4
    syscall
    j main

program_end:
    li $v0, 10
    syscall

# -------------------------------------------------------
# clear_board(a0=base)
# fills 49 integers with 0
clear_board:
    addi $sp, $sp, -8
    sw $ra, 4($sp)
    sw $s0, 0($sp)

    move $s0, $a0
    li $t0, 49
cb_loop:
    beqz $t0, cb_done
    sw $zero, 0($s0)
    addi $s0, $s0, 4
    addi $t0, $t0, -1
    j cb_loop
cb_done:
    lw $s0, 0($sp)
    lw $ra, 4($sp)
    addi $sp, $sp, 8
    jr $ra

# -------------------------------------------------------
# board_has_ship(a0=base) -> v0=1 if any cell==1 else 0
board_has_ship:
    move $t0, $a0
    li $t1, 49
bhs_loop:
    beqz $t1, bhs_no
    lw $t2, 0($t0)
    li $t3, 1
    beq $t2, $t3, bhs_yes
    addi $t0, $t0, 4
    addi $t1, $t1, -1
    j bhs_loop
bhs_yes:
    li $v0, 1
    jr $ra
bhs_no:
    move $v0, $zero
    jr $ra

# -------------------------------------------------------
# print_board(a0=base, a1=mode)
# mode=0 own board prints 0/1
# mode=1 memory board prints ./O/X where 0=.,1=O,2=X
print_board:
    addi $sp, $sp, -20
    sw $ra, 16($sp)
    sw $s0, 12($sp)
    sw $s1, 8($sp)
    sw $s2, 4($sp)
    sw $s3, 0($sp)

    move $s0, $a0
    move $s1, $a1

    la $a0, msgRowHeader
    li $v0, 4
    syscall

    li $s2, 0          # row
pb_row_loop:
    li $t0, 7
    beq $s2, $t0, pb_done

    # print row index and colon
    move $a0, $s2
    li $v0, 1
    syscall
    la $a0, msgColon
    li $v0, 4
    syscall

    li $s3, 0          # col
pb_col_loop:
    li $t0, 7
    beq $s3, $t0, pb_next_row

    li $t1, 7
    mul $t2, $s2, $t1
    add $t2, $t2, $s3
    sll $t2, $t2, 2
    add $t3, $s0, $t2
    lw $t4, 0($t3)

    beqz $s1, pb_mode_own

    # memory mode
    beqz $t4, pb_print_dot
    li $t5, 1
    beq $t4, $t5, pb_print_o
    j pb_print_x

pb_mode_own:
    beqz $t4, pb_print_zero
    j pb_print_one

pb_print_zero:
    la $a0, msgZero
    li $v0, 4
    syscall
    j pb_after_symbol
pb_print_one:
    la $a0, msgOne
    li $v0, 4
    syscall
    j pb_after_symbol
pb_print_dot:
    la $a0, msgDot
    li $v0, 4
    syscall
    j pb_after_symbol
pb_print_o:
    la $a0, msgO
    li $v0, 4
    syscall
    j pb_after_symbol
pb_print_x:
    la $a0, msgX
    li $v0, 4
    syscall

pb_after_symbol:
    la $a0, spaceStr
    li $v0, 4
    syscall
    addi $s3, $s3, 1
    j pb_col_loop

pb_next_row:
    la $a0, newline
    li $v0, 4
    syscall
    addi $s2, $s2, 1
    j pb_row_loop

pb_done:
    lw $s3, 0($sp)
    lw $s2, 4($sp)
    lw $s1, 8($sp)
    lw $s0, 12($sp)
    lw $ra, 16($sp)
    addi $sp, $sp, 20
    jr $ra

# -------------------------------------------------------
# setup_player(a0=board_base)
# Places 3 ships len2, 2 ships len3, 1 ship len4
setup_player:
    addi $sp, $sp, -12
    sw $ra, 8($sp)
    sw $s0, 4($sp)
    sw $s1, 0($sp)

    move $s0, $a0

    # len 2 x3
    li $s1, 3
sp_len2_loop:
    beqz $s1, sp_len3_start
sp_len2_retry:
    move $a0, $s0
    li $a1, 0
    jal print_board

    la $a0, msgLen2
    li $v0, 4
    syscall

    move $a0, $s0
    li $a1, 2
    jal read_and_place_ship

    beqz $v0, sp_len2_bad
    la $a0, msgShipPlaced
    li $v0, 4
    syscall
    addi $s1, $s1, -1
    j sp_len2_loop
    
sp_len2_bad:
    la $a0, msgInvalidShip
    li $v0, 4
    syscall
    j sp_len2_retry

sp_len3_start:
    li $s1, 2
sp_len3_loop:
    beqz $s1, sp_len4_start
sp_len3_retry:
    move $a0, $s0
    li $a1, 0
    jal print_board
    la $a0, msgLen3
    li $v0, 4
    syscall
    move $a0, $s0
    li $a1, 3
    jal read_and_place_ship
    beqz $v0, sp_len3_bad
    la $a0, msgShipPlaced
    li $v0, 4
    syscall
    addi $s1, $s1, -1
    j sp_len3_loop
sp_len3_bad:
    la $a0, msgInvalidShip
    li $v0, 4
    syscall
    j sp_len3_retry

sp_len4_start:
    li $s1, 1
sp_len4_loop:
    beqz $s1, sp_done
sp_len4_retry:
    move $a0, $s0
    li $a1, 0
    jal print_board
    la $a0, msgLen4
    li $v0, 4
    syscall
    move $a0, $s0
    li $a1, 4
    jal read_and_place_ship
    beqz $v0, sp_len4_bad
    la $a0, msgShipPlaced
    li $v0, 4
    syscall
    addi $s1, $s1, -1
    j sp_len4_loop
sp_len4_bad:
    la $a0, msgInvalidShip
    li $v0, 4
    syscall
    j sp_len4_retry

sp_done:
    move $a0, $s0
    li $a1, 0
    jal print_board
    lw $s1, 0($sp)
    lw $s0, 4($sp)
    lw $ra, 8($sp)
    addi $sp, $sp, 12
    jr $ra

# -------------------------------------------------------
# -------------------------------------------------------
# read_and_place_ship(a0=board_base, a1=required_len) -> v0=1 success else 0
# Reads 1 line, parses 4 ints, validates, checks overlap, places ship
read_and_place_ship:
    addi $sp, $sp, -36
    sw $ra, 32($sp)
    sw $s0, 28($sp)
    sw $s1, 24($sp)
    sw $s2, 20($sp)
    sw $s3, 16($sp)
    sw $s4, 12($sp)
    sw $s5, 8($sp)
    sw $s6, 4($sp)
    sw $s7, 0($sp)

    move $s0, $a0      # board base
    move $s1, $a1      # required len

    # read one whole line
    la $a0, inputBuffer
    li $a1, 64
    li $v0, 8
    syscall

    # parse 4 integers from buffer
    la $a0, inputBuffer
    jal parse_four_ints
    beqz $v0, rps_fail

    move $s2, $t0      # r1
    move $s3, $t1      # c1
    move $s4, $t2      # r2
    move $s5, $t3      # c2

    # bounds 0..6
    bltz $s2, rps_fail
    bltz $s3, rps_fail
    bltz $s4, rps_fail
    bltz $s5, rps_fail
    li $t0, 7
    bge $s2, $t0, rps_fail
    bge $s3, $t0, rps_fail
    bge $s4, $t0, rps_fail
    bge $s5, $t0, rps_fail

    # must be horizontal or vertical
    beq $s2, $s4, rps_horizontal
    beq $s3, $s5, rps_vertical
    j rps_fail

rps_horizontal:
    # length = abs(c2-c1)+1
    sub $t0, $s5, $s3
    bgez $t0, rps_h_pos
    sub $t0, $zero, $t0
rps_h_pos:
    addi $t0, $t0, 1
    bne $t0, $s1, rps_fail

    # start=min(c1,c2), end=max(c1,c2)
    slt $t1, $s3, $s5
    bnez $t1, rps_h_keep
    move $t2, $s5
    move $t3, $s3
    j rps_h_range_ready
rps_h_keep:
    move $t2, $s3
    move $t3, $s5
rps_h_range_ready:
    # check overlap row=s2 from col=t2..t3
    move $s6, $t2
rps_h_check_loop:
    bgt $s6, $t3, rps_h_place_start
    li $t4, 7
    mul $t5, $s2, $t4
    add $t5, $t5, $s6
    sll $t5, $t5, 2
    add $t6, $s0, $t5
    lw $t7, 0($t6)
    bnez $t7, rps_fail
    addi $s6, $s6, 1
    j rps_h_check_loop

rps_h_place_start:
    move $s6, $t2
rps_h_place_loop:
    bgt $s6, $t3, rps_success
    li $t4, 7
    mul $t5, $s2, $t4
    add $t5, $t5, $s6
    sll $t5, $t5, 2
    add $t6, $s0, $t5
    li $t7, 1
    sw $t7, 0($t6)
    addi $s6, $s6, 1
    j rps_h_place_loop

rps_vertical:
    # length = abs(r2-r1)+1
    sub $t0, $s4, $s2
    bgez $t0, rps_v_pos
    sub $t0, $zero, $t0
rps_v_pos:
    addi $t0, $t0, 1
    bne $t0, $s1, rps_fail

    # start=min(r1,r2), end=max(r1,r2)
    slt $t1, $s2, $s4
    bnez $t1, rps_v_keep
    move $t2, $s4
    move $t3, $s2
    j rps_v_range_ready
rps_v_keep:
    move $t2, $s2
    move $t3, $s4
rps_v_range_ready:
    move $s6, $t2
rps_v_check_loop:
    bgt $s6, $t3, rps_v_place_start
    li $t4, 7
    mul $t5, $s6, $t4
    add $t5, $t5, $s3
    sll $t5, $t5, 2
    add $t6, $s0, $t5
    lw $t7, 0($t6)
    bnez $t7, rps_fail
    addi $s6, $s6, 1
    j rps_v_check_loop

rps_v_place_start:
    move $s6, $t2
rps_v_place_loop:
    bgt $s6, $t3, rps_success
    li $t4, 7
    mul $t5, $s6, $t4
    add $t5, $t5, $s3
    sll $t5, $t5, 2
    add $t6, $s0, $t5
    li $t7, 1
    sw $t7, 0($t6)
    addi $s6, $s6, 1
    j rps_v_place_loop

rps_success:
    li $v0, 1
    j rps_exit

rps_fail:
    move $v0, $zero

rps_exit:
    lw $s7, 0($sp)
    lw $s6, 4($sp)
    lw $s5, 8($sp)
    lw $s4, 12($sp)
    lw $s3, 16($sp)
    lw $s2, 20($sp)
    lw $s1, 24($sp)
    lw $s0, 28($sp)
    lw $ra, 32($sp)
    addi $sp, $sp, 36
    jr $ra


# -------------------------------------------------------
# parse_four_ints(a0 = address of input string)
# Input example: "0 0 0 1"
# Output:
#   t0 = int1
#   t1 = int2
#   t2 = int3
#   t3 = int4
#   v0 = 1 if success, 0 if fail
parse_four_ints:
    addi $sp, $sp, -28
    sw $ra, 24($sp)
    sw $s0, 20($sp)
    sw $s1, 16($sp)
    sw $s2, 12($sp)
    sw $s3, 8($sp)
    sw $s4, 4($sp)
    sw $s5, 0($sp)

    move $s0, $a0          # pointer
    li $s1, 0              # count parsed


pfi_next_number:
    # skip spaces/newlines/tabs
pfi_skip_ws:
    lb $t4, 0($s0)
    beqz $t4, pfi_done_check
    li $t5, 32             # ' '
    beq $t4, $t5, pfi_skip_advance
    li $t5, 10             # '\n'
    beq $t4, $t5, pfi_skip_advance
    li $t5, 9              # '\t'
    beq $t4, $t5, pfi_skip_advance
    j pfi_start_parse

pfi_skip_advance:
    addi $s0, $s0, 1
    j pfi_skip_ws

pfi_start_parse:
    li $s2, 0              # current number
    li $s3, 0              # digit count

pfi_digit_loop:
    lb $t4, 0($s0)
    li $t5, 48             # '0'
    blt $t4, $t5, pfi_store_number
    li $t6, 57             # '9'
    bgt $t4, $t6, pfi_store_number

    addi $t4, $t4, -48
    mul $s2, $s2, 10
    add $s2, $s2, $t4
    addi $s3, $s3, 1
    addi $s0, $s0, 1
    j pfi_digit_loop

pfi_store_number:
    beqz $s3, pfi_fail     # no digits read

    beqz $s1, pfi_to_t0
    li $t7, 1
    beq $s1, $t7, pfi_to_t1
    li $t7, 2
    beq $s1, $t7, pfi_to_t2
    li $t7, 3
    beq $s1, $t7, pfi_to_t3
    j pfi_fail

pfi_to_t0:
    move $t0, $s2
    addi $s1, $s1, 1
    j pfi_after_store
pfi_to_t1:
    move $t1, $s2
    addi $s1, $s1, 1
    j pfi_after_store
pfi_to_t2:
    move $t2, $s2
    addi $s1, $s1, 1
    j pfi_after_store
pfi_to_t3:
    move $t3, $s2
    addi $s1, $s1, 1
    j pfi_after_store

pfi_after_store:
    li $t7, 4
    beq $s1, $t7, pfi_success
    j pfi_next_number

pfi_done_check:
    li $t7, 4
    beq $s1, $t7, pfi_success
    j pfi_fail

pfi_success:
    li $v0, 1
    j pfi_exit

pfi_fail:
    move $v0, $zero

pfi_exit:
    lw $s5, 0($sp)
    lw $s4, 4($sp)
    lw $s3, 8($sp)
    lw $s2, 12($sp)
    lw $s1, 16($sp)
    lw $s0, 20($sp)
    lw $ra, 24($sp)
    addi $sp, $sp, 28
    jr $ra
    
    
# -------------------------------------------------------
# parse_two_ints(a0 = address of input string)
# Input example: "3 4"
# Output:
#   t0 = int1
#   t1 = int2
#   v0 = 1 if success, 0 if fail
parse_two_ints:
    addi $sp, $sp, -24
    sw $ra, 20($sp)
    sw $s0, 16($sp)
    sw $s1, 12($sp)
    sw $s2, 8($sp)
    sw $s3, 4($sp)
    sw $s4, 0($sp)

    move $s0, $a0          # pointer
    li $s1, 0              # count parsed

pti_next_number:
pti_skip_ws:
    lb $t4, 0($s0)
    beqz $t4, pti_done_check
    li $t5, 32             # ' '
    beq $t4, $t5, pti_skip_advance
    li $t5, 10             # '\n'
    beq $t4, $t5, pti_skip_advance
    li $t5, 9              # '\t'
    beq $t4, $t5, pti_skip_advance
    j pti_start_parse

pti_skip_advance:
    addi $s0, $s0, 1
    j pti_skip_ws

pti_start_parse:
    li $s2, 0              # current number
    li $s3, 0              # digit count

pti_digit_loop:
    lb $t4, 0($s0)
    li $t5, 48             # '0'
    blt $t4, $t5, pti_store_number
    li $t6, 57             # '9'
    bgt $t4, $t6, pti_store_number

    addi $t4, $t4, -48
    mul $s2, $s2, 10
    add $s2, $s2, $t4
    addi $s3, $s3, 1
    addi $s0, $s0, 1
    j pti_digit_loop

pti_store_number:
    beqz $s3, pti_fail

    beqz $s1, pti_to_t0
    li $t7, 1
    beq $s1, $t7, pti_to_t1
    j pti_fail

pti_to_t0:
    move $t0, $s2
    addi $s1, $s1, 1
    j pti_after_store

pti_to_t1:
    move $t1, $s2
    addi $s1, $s1, 1
    j pti_after_store

pti_after_store:
    li $t7, 2
    beq $s1, $t7, pti_success
    j pti_next_number

pti_done_check:
    li $t7, 2
    beq $s1, $t7, pti_success
    j pti_fail

pti_success:
    li $v0, 1
    j pti_exit

pti_fail:
    move $v0, $zero

pti_exit:
    lw $s4, 0($sp)
    lw $s3, 4($sp)
    lw $s2, 8($sp)
    lw $s1, 12($sp)
    lw $s0, 16($sp)
    lw $ra, 20($sp)
    addi $sp, $sp, 24
    jr $ra

# -------------------------------------------------------
# print_dual_boards(a0=ownBoard, a1=opponentShotsMem, a2=myTargetMem)
#
# Left board:
#   1 = alive ship
#   X = my ship got hit
#   O = opponent shot empty cell
#   . = untouched empty cell
#
# Right board:
#   . = unknown
#   O = miss
#   X = hit
print_dual_boards:
    addi $sp, $sp, -28
    sw $ra, 24($sp)
    sw $s0, 20($sp)
    sw $s1, 16($sp)
    sw $s2, 12($sp)
    sw $s3, 8($sp)
    sw $s4, 4($sp)
    sw $s5, 0($sp)

    move $s0, $a0          # own board
    move $s1, $a1          # opponent shots memory on me
    move $s2, $a2          # my target memory

    # title
    la $a0, msgDualTitle
    li $v0, 4
    syscall

    # header left: 3 spaces + 7 column numbers
    la $a0, spaceStr
    li $v0, 4
    syscall
    la $a0, spaceStr
    li $v0, 4
    syscall
    la $a0, spaceStr
    li $v0, 4
    syscall

    li $s3, 0
pdb_header_left:
    li $t0, 7
    beq $s3, $t0, pdb_header_gap

    move $a0, $s3
    li $v0, 1
    syscall
    la $a0, spaceStr
    li $v0, 4
    syscall

    addi $s3, $s3, 1
    j pdb_header_left

pdb_header_gap:
    la $a0, midGap
    li $v0, 4
    syscall

    # header right: 3 spaces + 7 column numbers
    la $a0, spaceStr
    li $v0, 4
    syscall
    la $a0, spaceStr
    li $v0, 4
    syscall
    la $a0, spaceStr
    li $v0, 4
    syscall

    li $s3, 0
pdb_header_right:
    li $t0, 7
    beq $s3, $t0, pdb_header_done

    move $a0, $s3
    li $v0, 1
    syscall
    la $a0, spaceStr
    li $v0, 4
    syscall

    addi $s3, $s3, 1
    j pdb_header_right

pdb_header_done:
    la $a0, newline
    li $v0, 4
    syscall

    # rows
    li $s3, 0              # row
pdb_row_loop:
    li $t0, 7
    beq $s3, $t0, pdb_done

    # left row label
    move $a0, $s3
    li $v0, 1
    syscall
    la $a0, msgColon
    li $v0, 4
    syscall

    li $s4, 0              # left col
pdb_left_col_loop:
    li $t0, 7
    beq $s4, $t0, pdb_mid_gap

    li $t1, 7
    mul $t2, $s3, $t1
    add $t2, $t2, $s4
    sll $t2, $t2, 2

    add $t3, $s0, $t2      # own board
    lw $t4, 0($t3)

    add $t5, $s1, $t2      # opponent shots on me
    lw $t6, 0($t5)

    li $t7, 1
    beq $t4, $t7, pdb_left_one

    beqz $t6, pdb_left_dot
    li $t7, 1
    beq $t6, $t7, pdb_left_o
    j pdb_left_x

pdb_left_one:
    la $a0, msgOne
    li $v0, 4
    syscall
    j pdb_left_after

pdb_left_dot:
    la $a0, msgDot
    li $v0, 4
    syscall
    j pdb_left_after

pdb_left_o:
    la $a0, msgO
    li $v0, 4
    syscall
    j pdb_left_after

pdb_left_x:
    la $a0, msgX
    li $v0, 4
    syscall

pdb_left_after:
    la $a0, spaceStr
    li $v0, 4
    syscall
    addi $s4, $s4, 1
    j pdb_left_col_loop

pdb_mid_gap:
    la $a0, midGap
    li $v0, 4
    syscall

    # right row label
    move $a0, $s3
    li $v0, 1
    syscall
    la $a0, msgColon
    li $v0, 4
    syscall

    li $s5, 0              # right col
pdb_right_col_loop:
    li $t0, 7
    beq $s5, $t0, pdb_next_row

    li $t1, 7
    mul $t2, $s3, $t1
    add $t2, $t2, $s5
    sll $t2, $t2, 2

    add $t3, $s2, $t2
    lw $t4, 0($t3)

    beqz $t4, pdb_right_dot
    li $t5, 1
    beq $t4, $t5, pdb_right_o
    j pdb_right_x

pdb_right_dot:
    la $a0, msgDot
    li $v0, 4
    syscall
    j pdb_right_after

pdb_right_o:
    la $a0, msgO
    li $v0, 4
    syscall
    j pdb_right_after

pdb_right_x:
    la $a0, msgX
    li $v0, 4
    syscall

pdb_right_after:
    la $a0, spaceStr
    li $v0, 4
    syscall
    addi $s5, $s5, 1
    j pdb_right_col_loop

pdb_next_row:
    la $a0, newline
    li $v0, 4
    syscall
    addi $s3, $s3, 1
    j pdb_row_loop

pdb_done:
    lw $s5, 0($sp)
    lw $s4, 4($sp)
    lw $s3, 8($sp)
    lw $s2, 12($sp)
    lw $s1, 16($sp)
    lw $s0, 20($sp)
    lw $ra, 24($sp)
    addi $sp, $sp, 28
    jr $ra

# -------------------------------------------------------
# choose_game_mode: get 1 (one player) or 2 (two players)
# Returns: v0 = 1 or 2
choose_game_mode:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    la $a0, msgModeTitle
    li $v0, 4
    syscall
    la $a0, newline
    li $v0, 4
    syscall

    la $a0, msgModeOption1
    li $v0, 4
    syscall
    la $a0, newline
    li $v0, 4
    syscall

    la $a0, msgModeOption2
    li $v0, 4
    syscall
    la $a0, newline
    li $v0, 4
    syscall

cgm_loop:
    la $a0, msgModePrompt
    li $v0, 4
    syscall

    li $v0, 5
    syscall
    move $t0, $v0

    li $t1, 1
    beq $t0, $t1, cgm_ok
    li $t1, 2
    beq $t0, $t1, cgm_ok

    la $a0, msgModeInvalid
    li $v0, 4
    syscall
    j cgm_loop

cgm_ok:
    move $v0, $t0
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# -------------------------------------------------------
# load_auto_board(a0=dest_board)
load_auto_board:
    addi $sp, $sp, -8
    sw $ra, 4($sp)
    sw $s0, 0($sp)

    move $s0, $a0
    la $t0, autoBoardTemplate
    li $t1, 49

lab_copy_loop:
    beqz $t1, lab_done
    lw $t2, 0($t0)
    sw $t2, 0($s0)
    addi $t0, $t0, 4
    addi $s0, $s0, 4
    addi $t1, $t1, -1
    j lab_copy_loop

lab_done:
    lw $s0, 0($sp)
    lw $ra, 4($sp)
    addi $sp, $sp, 8
    jr $ra

# -------------------------------------------------------
# computer_attack: attack first untargeted cell on P1 board
computer_attack:
    la $t0, memP2
    la $t1, boardP1
    li $t2, 0

ca_find_cell:
    li $t3, 49
    beq $t2, $t3, ca_done

    sll $t4, $t2, 2
    add $t5, $t0, $t4
    lw $t6, 0($t5)
    beqz $t6, ca_attack_here

    addi $t2, $t2, 1
    j ca_find_cell

ca_attack_here:
    add $t7, $t1, $t4
    lw $t8, 0($t7)
    beqz $t8, ca_miss

    sw $zero, 0($t7)
    li $t9, 2
    sw $t9, 0($t5)
    la $a0, msgHit
    li $v0, 4
    syscall
    j ca_done

ca_miss:
    li $t9, 1
    sw $t9, 0($t5)
    la $a0, msgMiss
    li $v0, 4
    syscall

ca_done:
    jr $ra
# -------------------------------------------------------
# show_menu: Display main menu and get user choice
# Returns: $v0 = 0 if play, 1 if help
show_menu:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    la $a0, newline
    li $v0, 4
    syscall
    
    la $a0, msgMenuTitle
    li $v0, 4
    syscall
    
    la $a0, newline
    li $v0, 4
    syscall
    la $a0, newline
    li $v0, 4
    syscall
    
    la $a0, msgMenuOption1
    li $v0, 4
    syscall
    
    la $a0, newline
    li $v0, 4
    syscall
    
    la $a0, msgMenuOption2
    li $v0, 4
    syscall

    la $a0, newline
    li $v0, 4
    syscall

    la $a0, msgMenuOption3
    li $v0, 4
    syscall
    
    la $a0, newline
    li $v0, 4
    syscall
    la $a0, newline
    li $v0, 4
    syscall
    
menu_input_loop:
    la $a0, msgMenuOption0
    li $v0, 4
    syscall
    
    li $v0, 5
    syscall
    move $t0, $v0
    
    li $t1, 1
    beq $t0, $t1, menu_choose_play
    
    li $t1, 2
    beq $t0, $t1, menu_choose_help

    li $t1, 3
    beq $t0, $t1, menu_choose_quit
    
    la $a0, msgMenuInvalid
    li $v0, 4
    syscall
    j menu_input_loop
    
menu_choose_play:
    move $v0, $zero
    j menu_exit
    
menu_choose_help:
    li $v0, 1
    j menu_exit

menu_choose_quit:
    li $v0, 2
    
menu_exit:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# -------------------------------------------------------
# show_help: Display game instructions
show_help:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    la $a0, msgHelpHeader
    li $v0, 4
    syscall
    
    la $a0, newline
    li $v0, 4
    syscall
    
    la $a0, msgHelpLine1
    li $v0, 4
    syscall
    
    la $a0, newline
    li $v0, 4
    syscall
    
    la $a0, msgHelpLine2
    li $v0, 4
    syscall
    
    la $a0, newline
    li $v0, 4
    syscall
    
    la $a0, msgHelpLine3
    li $v0, 4
    syscall
    
    la $a0, newline
    li $v0, 4
    syscall
    
    la $a0, msgHelpLine4
    li $v0, 4
    syscall
    
    la $a0, newline
    li $v0, 4
    syscall
    
    la $a0, msgHelpLine5
    li $v0, 4
    syscall
    
    la $a0, newline
    li $v0, 4
    syscall
    
    la $a0, msgHelpLine6
    li $v0, 4
    syscall
    
    la $a0, newline
    li $v0, 4
    syscall
    
    la $a0, msgHelpLine7
    li $v0, 4
    syscall
    
    la $a0, msgHelpFooter
    li $v0, 4
    syscall
    
    la $a0, inputBuffer
    li $a1, 64
    li $v0, 8
    syscall
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# -------------------------------------------------------
# pause_for_swap: wait for Enter-ish input handoff point
pause_for_swap:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    la $a0, msgEnterHidden
    li $v0, 4
    syscall
    # Read one char twice if needed to consume newline leftovers safely
    li $v0, 12
    syscall
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
