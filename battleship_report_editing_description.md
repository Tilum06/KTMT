# Mô tả chỉnh sửa report Battleship MIPS

## 1. Nhận xét chung

Report hiện tại đang quá dài so với yêu cầu của một bài Computer Architecture Lab. Nội dung có nhiều phần đúng và chi tiết, nhưng bị dàn trải thành quá nhiều chương nhỏ. Một số phần đang giống tài liệu giảng lại MIPS hơn là báo cáo mô tả implementation của chương trình Battleship.

Mục tiêu chỉnh sửa nên là:

- Rút report từ khoảng 13 chương xuống còn 8–9 chương.
- Giảm độ dài từ khoảng 70 trang xuống khoảng 20–30 trang.
- Tập trung vào yêu cầu đề bài, thiết kế dữ liệu, thuật toán setup, thuật toán battle, hướng dẫn dùng và kiểm thử.
- Không chèn code MIPS nguyên văn.
- Chỉ dùng mô tả bằng lời, bảng, flowchart hoặc pseudocode mức cao.
- Chỉnh các đoạn chưa khớp với code thực tế.

---

## 2. Cấu trúc report đề xuất

Nên đổi cấu trúc report thành:


Nếu muốn ngắn hơn nữa, có thể dùng:

```text
1. Introduction
2. Requirements
3. Design and Implementation
4. User Guide
5. Testing
6. Conclusion
```

---

## 3. Các phần nên giữ

### 3.1 Introduction

Giữ phần giới thiệu ngắn về Battleship, mục tiêu assignment và môi trường thực hiện.

Nên rút còn khoảng 0.5–1 trang.

Nội dung nên có:

- Battleship là trò chơi chiến lược giữa hai người chơi.
- Assignment yêu cầu mô phỏng Battleship bằng MIPS Assembly.
- Chương trình chạy trên MARS simulator.
- Bàn cờ được rút gọn còn 7x7.

Không cần liệt kê quá dài các kỹ năng MIPS ở phần mở đầu.

---

### 3.2 Requirement Analysis

Giữ phần tóm tắt yêu cầu đề bài.

Nên trình bày bằng bảng:

| Requirement | Description |
|---|---|
| Board size | 7x7 |
| Fleet | 3 ships length 2, 2 ships length 3, 1 ship length 4 |
| Placement | Horizontal or vertical, no overlap |
| Attack input | row and column |
| Result | HIT or MISS |
| End condition | One board has no remaining ship cells |

Nên bỏ phần “Yêu cầu về báo cáo” khỏi nội dung chính vì đây không phải là nội dung implementation.

---

### 3.3 Program Design and Data Representation

Nên gộp chương “Tổng quan thiết kế chương trình” và “Biểu diễn dữ liệu” thành một chương.

Nội dung nên giữ:

- Luồng tổng quát của chương trình.
- Các phase chính: menu, setup, battle, win checking.
- Các mảng dữ liệu chính:
  - `boardP1`
  - `boardP2`
  - `memP1`
  - `memP2`
  - `gameMode`
  - `inputBuffer`
  - `autoBoardTemplate`
- Cách ánh xạ bàn cờ 2D sang mảng 1D.

Công thức quan trọng cần giữ:

```text
index = row * 7 + column
byte_offset = index * 4
```

Nên giữ ví dụ ngắn:

```text
Cell (3, 3):
index = 3 * 7 + 3 = 24
byte_offset = 24 * 4 = 96
```

Không cần đưa quá nhiều ví dụ tọa độ.

---

### 3.4 Ship Placement Algorithm

Giữ phần thuật toán đặt tàu nhưng rút lại.

Nên trình bày theo luồng:

1. Người chơi nhập 4 số:
   ```text
   row_bow col_bow row_stern col_stern
   ```
2. Parse input thành 4 số nguyên.
3. Kiểm tra tọa độ nằm trong `[0, 6]`.
4. Kiểm tra tàu nằm ngang hoặc dọc.
5. Tính độ dài tàu.
6. So sánh với độ dài yêu cầu.
7. Kiểm tra overlap.
8. Nếu hợp lệ, ghi giá trị `1` vào các ô tàu chiếm.

Có thể viết dạng ngắn:

```text
A ship is accepted only if:
- all coordinates are inside [0, 6];
- the ship is horizontal or vertical;
- the calculated length equals the required length;
- all occupied cells are currently empty.
```

Không cần chia quá nhiều subsection kiểu “Bước 1”, “Bước 2”, “Bước 3” nếu mỗi bước chỉ có vài dòng.

---

### 3.5 Battle Phase Algorithm

Giữ phần thuật toán chiến đấu.

Nên trình bày theo luồng:

1. Hiển thị board của người chơi hiện tại và enemy map.
2. Người chơi nhập tọa độ tấn công:
   ```text
   row col
   ```
3. Parse input thành 2 số nguyên.
4. Kiểm tra tọa độ trong `[0, 6]`.
5. Kiểm tra ô này đã bắn chưa bằng memory board.
6. Nếu chưa bắn:
   - Nếu ô trên board đối phương là `1`: HIT.
   - Nếu ô trên board đối phương là `0`: MISS.
7. Cập nhật board và memory board.
8. Kiểm tra điều kiện thắng.

Nên giữ logic cập nhật:

```text
If opponent_board[index] == 1:
    print HIT
    opponent_board[index] = 0
    attacker_memory[index] = 2
Else:
    print MISS
    attacker_memory[index] = 1
```

Không cần tách quá dài thành 3 tình huống riêng: bắn trúng, bắn hụt, bắn lặp.

---

### 3.6 MIPS Implementation Notes

Nên rút chương “Tổ chức thủ tục và khái niệm MIPS” thành một mục ngắn.

Chỉ cần nói những điểm MIPS liên quan trực tiếp đến chương trình:

- Chương trình được chia thành nhiều procedure để dễ tổ chức.
- `jal` dùng để gọi procedure.
- `jr $ra` dùng để quay về nơi gọi.
- Stack dùng để lưu `$ra` và các thanh ghi `$s` khi procedure gọi procedure khác.
- `lw` và `sw` dùng để truy cập board trong bộ nhớ.
- Syscall dùng cho nhập/xuất terminal.
- Branch/jump dùng để kiểm tra điều kiện và điều khiển vòng lặp.

Không cần giải thích dài từng lệnh MIPS như giáo trình.

---

### 3.7 User Interface and User Guide

Nên gộp phần UI Design và User Guide thành một chương.

Nội dung nên có:

- Cách chạy chương trình bằng MARS.
- Cách dùng menu:
  - Play Game
  - Instructions
  - Quit
- Cách chọn chế độ:
  - One Player
  - Two Players
- Cách nhập tọa độ đặt tàu.
- Cách nhập tọa độ bắn.
- Ý nghĩa ký hiệu trên board.

Bảng ký hiệu nên giữ:

| Symbol | Meaning |
|---|---|
| `1` | own ship cell |
| `.` | unknown or empty |
| `O` | miss |
| `X` | hit |

---

### 3.8 Testing and Results

Giữ phần testing nhưng rút còn bảng test case và một vài nhận xét.

Nên có bảng:

| Test case | Input | Expected result |
|---|---|---|
| Valid length-2 ship | `0 0 0 1` | Ship placed successfully |
| Invalid diagonal ship | `0 0 1 1` | Invalid ship |
| Out of range coordinate | `0 0 0 7` | Invalid ship |
| Overlapping ship | Same cells as previous ship | Invalid ship |
| Valid attack | `3 4` | HIT or MISS |
| Repeated attack | Attack same cell twice | Rejected |
| Win condition | Destroy all enemy cells | Player wins |

Nên bỏ hoặc rút mạnh:

- Bottom-up testing.
- Boundary testing.
- Negative testing.
- Bug report format.
- Testing tools nếu chỉ là MARS.

---

### 3.9 Conclusion

Rút conclusion còn khoảng 0.5–1 trang.

Nội dung nên có:

- Chương trình đã mô phỏng Battleship 7x7 bằng MIPS.
- Có setup phase, battle phase, HIT/MISS và win condition.
- Có chế độ One Player và Two Players.
- Qua bài này luyện tập array, procedure, branch, loop, syscall và memory access trong MIPS.
- Nêu ngắn một vài cải tiến có thể.

Không nên chia conclusion thành quá nhiều subsection.

---

## 4. Các phần nên rút hoặc bỏ

### 4.1 Phần lý thuyết MIPS quá dài

Nên rút các mục:

- Giải thích chi tiết `jal`.
- Giải thích chi tiết `jr $ra`.
- Bảng syscall phổ biến.
- Bảng branch instruction.
- Bảng arithmetic instruction.
- Bảng memory instruction.
- Ví dụ MIPS quá cơ bản.

Chỉ giữ các ý liên hệ trực tiếp đến chương trình Battleship.

---

### 4.2 Phần Input Parsing quá chi tiết

Không cần một chương riêng quá dài cho parsing.

Chỉ cần mô tả:

- `parse_four_ints` dùng cho input đặt tàu.
- `parse_two_ints` dùng cho input tấn công.
- Hai thủ tục bỏ qua khoảng trắng và chuyển ký tự số thành số nguyên.

Không cần mô tả chi tiết từng ký tự, best practice hoặc giới hạn quá dài.

---

### 4.3 Phần Computer mode quá dài

Computer trong code không phải AI phức tạp.

Chỉ nên mô tả:

- Computer dùng board mẫu có sẵn.
- Khi đến lượt, computer quét từ index 0 đến 48.
- Computer chọn ô đầu tiên chưa bị bắn.
- Chiến lược đơn giản nhưng đủ để mô phỏng chế độ một người.

Không nên dùng cụm “Computer AI” nếu không có chiến lược thông minh.

---

### 4.4 Phần Future Improvements quá xa

Nên bỏ hoặc rút các cải tiến quá xa assignment như:

- Network feature.
- Leaderboard.
- Giao diện đồ họa nâng cao.
- Multiplayer online.

Chỉ nên giữ cải tiến thực tế:

- Random computer attack.
- Smarter computer attack after HIT.
- Move history file.
- Configurable board size.
- Better input handling.

---

## 5. Các lỗi/chỗ chưa khớp code cần sửa

### 5.1 Không gọi là `player_attack` nếu code không có procedure này

Trong code, logic tấn công của Player 1 và Player 2 nằm trực tiếp trong `game_loop` với các label như `p1_attack_retry`, `p2_attack_retry`.

Vì vậy không nên viết:

```text
Thủ tục player_attack xử lý một lượt tấn công.
```

Nên sửa thành:

```text
The attack handling logic is implemented inside the main game loop for Player 1 and Player 2. Both parts follow the same logic: read target coordinates, validate them, check repeated shots, update the opponent board, update the memory board, and check the win condition.
```

---

### 5.2 Không nói `setup_player` clear board

Trong code, board được clear trước khi gọi `setup_player`, không phải bên trong `setup_player`.

Nên sửa từ:

```text
setup_player clears the board.
```

thành:

```text
Before the setup phase, all boards and memory boards are initialized to zero. Then setup_player is called to place the required ships on the selected board.
```

---

### 5.3 Sửa kích thước `inputBuffer`

Trong code:

```asm
inputBuffer: .space 64
```

Vì vậy report phải ghi:

```text
inputBuffer is a 64-byte buffer used to store one line of user input.
```

Không ghi “khoảng 100–256 byte”.

---

### 5.4 Không phóng đại Computer

Không nên viết:

```text
Computer AI
```

Nên viết:

```text
Computer behavior
```

hoặc:

```text
Automatic computer move
```

Vì computer chỉ bắn ô chưa bắn đầu tiên.

---

### 5.5 Chỉnh lỗi ký tự trong công thức

Trong report có lỗi hiển thị ký tự nhân thành `Ö`.

Nên sửa:

```text
7Ö7
row Ö 7 + col
index Ö 4
```

thành:

```text
7x7
row * 7 + col
index * 4
```

---

## 6. Độ dài đề xuất

| Phần | Số trang nên có |
|---|---:|
| Introduction + Requirements | 2–3 |
| Design + Data Representation | 4–5 |
| Setup Algorithm | 3–4 |
| Battle Algorithm | 3–4 |
| MIPS Notes | 2–3 |
| User Guide | 2–3 |
| Testing | 3–5 |
| Conclusion | 1 |
| Tổng | 20–30 |

---

## 7. Prompt dùng để yêu cầu AI chỉnh report

```text
Hãy chỉnh sửa report Battleship MIPS này theo hướng ngắn gọn, rõ ràng và bám sát implementation thực tế.

Yêu cầu:
1. Rút report từ 13 chương xuống khoảng 8–9 chương.
2. Giữ các phần quan trọng: yêu cầu đề bài, biểu diễn board 7x7 bằng mảng 1D, công thức index = row * 7 + col, setup phase, battle phase, memory board, HIT/MISS, win condition, one-player/two-player mode, user guide, testing.
3. Lược bỏ hoặc rút ngắn các phần quá lý thuyết như giải thích jal, jr $ra, syscall, branch, stack nếu không liên hệ trực tiếp đến chương trình.
4. Không chèn code MIPS nguyên văn. Chỉ dùng mô tả bằng lời, bảng, flowchart hoặc pseudocode mức cao.
5. Chỉnh các chỗ chưa đúng với code:
   - Không gọi là procedure player_attack nếu code không có procedure riêng tên này.
   - Không nói setup_player clear board nếu board được clear trước khi gọi setup_player.
   - inputBuffer có kích thước 64 bytes.
   - Computer chỉ dùng chiến lược bắn ô chưa bắn đầu tiên, không gọi là AI phức tạp.
6. Rút phần Computer mode còn khoảng 0.5–1 trang.
7. Rút phần Limitations and Improvements còn các cải tiến thực tế như random attack, smarter computer attack, move history, configurable board size.
8. Rút Conclusion còn 0.5–1 trang.
9. Văn phong báo cáo kỹ thuật, rõ ràng, không quá dài dòng.
```

---

## 8. Kết luận chỉnh sửa

Nên giữ trọng tâm của report ở các phần:

- Requirement Analysis.
- Data Representation.
- Ship Placement Algorithm.
- Battle Phase Algorithm.
- Testing.

Nên rút mạnh các phần:

- Lý thuyết MIPS chung.
- Input parsing quá chi tiết.
- UI design quá dài.
- Computer mode quá dài.
- Future improvements quá xa.

Sau khi chỉnh, report sẽ gọn hơn, sát code hơn và phù hợp với rubric hơn.
