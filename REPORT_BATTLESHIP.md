# BATTLESHIP - Triển Khai MIPS Assembly

## 1. TRANG TIÊU ĐỀ

**Tiêu đề:** BATTLESHIP - MIPS Assembly Implementation  
**Môn học:** Computer Architecture Lab (CO2008)  
**Trường:** Đại học Bách Khoa Thành phố Hồ Chí Minh  
**Năm học:** 2024-2025  
**Nền tảng:** MARS MIPS Simulator  

---

## 2. GIỚI THIỆU

### 2.1 Giới thiệu về trò chơi Battleship
Battleship là một trò chơi chiến thuật cổ điển giữa hai người chơi, mỗi người quản lý một hạm đội trên bàn cờ lưới. Mục tiêu của mỗi người chơi là tìm và phá hủy toàn bộ tàu của đối thủ trước khi tàu của họ bị phá hủy.

### 2.2 Mục tiêu assignment
Assignment này yêu cầu mô phỏng trò chơi Battleship trên bàn cờ 7×7 sử dụng ngôn ngữ Assembly MIPS trên nền tảng MARS. Chương trình phải triển khai đầy đủ các giai đoạn setup và battle, đơn giản hóa logic phù hợp với khả năng MARS MIPS.

### 2.3 Kỹ năng áp dụng
- **Arithmetic instructions:** Tính toán chỉ số mảng, độ dài tàu
- **Memory/Data transfer:** Truy cập bảng dữ liệu board, memory
- **Branch/Jump:** Điều kiện validate, vòng lặp setup/battle
- **Procedure call:** Chia chương trình thành các thủ tục (jal/jr $ra)
- **Stack usage:** Bảo toàn thanh ghi trong các thủ tục lồng nhau
- **String/Integer syscalls:** In bàn cờ, đọc input, xử lý ký tự

---

## 3. PHÂN TÍCH YÊU CẦU

### 3.1 Yêu cầu cơ bản
- **Kích thước bàn cờ:** 7×7 ô (49 ô tổng cộng)
- **Hạm đội mỗi người chơi:**
  - 3 tàu dài 2 ô
  - 2 tàu dài 3 ô
  - 1 tàu dài 4 ô
- **Input đặt tàu:** Bốn tọa độ (hàng_mũi, cột_mũi, hàng_lái, cột_lái)

### 3.2 Ràng buộc hợp lệ khi đặt tàu
1. Cả bốn tọa độ phải nằm trong khoảng [0, 6]
2. Tàu phải nằm ngang (hàng bằng nhau) hoặc dọc (cột bằng nhau)
3. Chiều dài tính được = |hiệu tọa độ| + 1 phải khớp với loại tàu
4. Không được chồng lấn với tàu đã đặt trước đó

### 3.3 Quy ước biểu diễn dữ liệu
- **Board (boardP1, boardP2):** Mảng 49 số nguyên, 0 = ô trống/đã bị phá hủy, 1 = tàu còn nguyên vẹn
- **Memory (memP1, memP2):** Mảng 49 số nguyên, 0 = chưa bắn, 1 = trượt, 2 = trúng

---

## 4. TỔNG QUAN THIẾT KẾ CHƯƠNG TRÌNH

### 4.1 Cấu trúc ba phần chính

Chương trình chia thành ba giai đoạn lớn:

#### Giai đoạn 1: Giao diện và chọn chế độ
- Hiển thị menu chính (Play, Instructions, Quit)
- Hiển thị hướng dẫn cách chơi nếu người dùng chọn
- Lựa chọn chế độ chơi: One Player (vs Computer) hay Two Players

#### Giai đoạn 2: Setup
- Khởi tạo các board thành 0
- Người chơi 1 đặt tàu
- Nếu chế độ Two Players, người chơi 2 đặt tàu; nếu One Player, Computer tự động đặt tàu
- Xác thực từng tàu trước khi chấp nhận

#### Giai đoạn 3: Battle Loop
- Lần lượt cho người chơi 1 và người chơi 2 (hoặc Computer) tấn công
- Mỗi lượt: nhập tọa độ mục tiêu, kiểm tra trúng/trượt, cập nhật bàn cờ
- Kiểm tra điều kiện thắng sau mỗi lượt
- Game kết thúc khi board của một người không còn ô nào có giá trị 1

### 4.2 Luồng chính (Main Flow)

```
Khởi động
  ↓
Hiển thị Menu → Chọn "Play"
  ↓
Chọn chế độ chơi (1 hoặc 2)
  ↓
Khởi tạo tất cả board = 0
  ↓
Setup Người chơi 1
  ↓
Setup Người chơi 2/Computer
  ↓
Bắt đầu Battle Loop
  ├─ Lượt P1: Nhập tọa độ → Kiểm tra → Hit/Miss → Kiểm tra thắng
  ├─ Lượt P2: Nhập tọa độ → Kiểm tra → Hit/Miss → Kiểm tra thắng
  └─ (Lặp lại cho đến khi có người thắng)
  ↓
Thông báo người thắng
  ↓
Quay lại Menu hoặc Thoát
```

---

## 5. BIỂU DIỄN DỮ LIỆU

### 5.1 Ánh xạ bàn cờ 7×7 sang mảng 1 chiều

Bàn cờ 7×7 được ánh xạ thành mảng 49 phần tử theo thứ tự hàng-cột:
- **Công thức chỉ số:** `index = hàng × 7 + cột`
- **Ví dụ:** Ô (3, 2) → chỉ số 3×7 + 2 = 23
- **Byte offset:** `offset = index × 4` (vì mỗi integer 4 byte)

### 5.2 Ý nghĩa dữ liệu

#### Board của người chơi (boardP1, boardP2)
- **1:** Ô chứa tàu còn nguyên vẹn
- **0:** Ô trống hoặc đã bị phá hủy

#### Memory/Bản ghi bắn (memP1, memP2)
- **0:** Chưa bắn vào ô này (Unknown)
- **1:** Đã bắn vào ô này nhưng trượt (Miss)
- **2:** Đã bắn vào ô này và trúng (Hit)

### 5.3 Hiển thị trên màn hình

**Board của bản thân:**
- `1` → ô có tàu
- `.` → ô trống (chưa bị bắn)
- `X` → tàu bị phá hủy (đã bắn trúng)
- `O` → bắn vào ô trống (trượt)

**Enemy Map (Bản đồ kẻ địch):**
- `.` → chưa biết (Unknown)
- `O` → bắn vào ô trống
- `X` → bắn trúng tàu đối phương

---

## 6. THUẬT TOÁN GIA ĐOẠN SETUP

### 6.1 Quá trình setup_player

Thủ tục setup_player được gọi cho mỗi người chơi, yêu cầu họ đặt lần lượt:
1. Ba tàu dài 2 ô (3 lần gọi read_and_place_ship với độ dài mong muốn = 2)
2. Hai tàu dài 3 ô (2 lần gọi với độ dài = 3)
3. Một tàu dài 4 ô (1 lần gọi với độ dài = 4)

Nếu input không hợp lệ, chương trình yêu cầu nhập lại cho đến khi tàu được chấp nhận.

### 6.2 Thuật toán read_and_place_ship (chi tiết)

**Bước 1: Đọc input**
- Hiển thị prompt yêu cầu nhập bốn tọa độ
- Đọc cả dòng vào inputBuffer

**Bước 2: Parse bốn số nguyên**
- Gọi parse_four_ints để tách chuỗi thành: row_bow, col_bow, row_stern, col_stern
- Nếu parse thất bại (không đúng 4 số), từ chối và yêu cầu nhập lại

**Bước 3: Kiểm tra phạm vi**
- Verify: 0 ≤ row_bow, col_bow, row_stern, col_stern ≤ 6
- Nếu vi phạm → từ chối

**Bước 4: Kiểm tra hướng (ngang hoặc dọc)**
- **Ngang:** row_bow == row_stern và col_bow ≠ col_stern
- **Dọc:** col_bow == col_stern và row_bow ≠ row_stern
- **Sai:** Tất cả các trường hợp khác (bao gồm chéo hoặc cùng điểm) → từ chối

**Bước 5: Tính độ dài**
- Nếu ngang: `length = |col_stern - col_bow| + 1`
- Nếu dọc: `length = |row_stern - row_bow| + 1`
- So sánh với độ dài mong muốn (2, 3, hoặc 4)
- Nếu không khớp → từ chối

**Bước 6: Kiểm tra chồng lấn**
- Duyệt tất cả ô mà tàu sẽ chiếm:
  - Nếu ngang: từ cột nhỏ đến cột lớn, cùng hàng
  - Nếu dọc: từ hàng nhỏ đến hàng lớn, cùng cột
- Kiểm tra từng ô trên board: nếu giá trị ≠ 0, có chồng lấn → từ chối

**Bước 7: Đặt tàu (nếu hợp lệ)**
- Ghi giá trị 1 vào mỗi ô mà tàu chiếm
- Thông báo "Ship placed successfully"

**Pseudocode (mức cao):**
```
Hàm read_and_place_ship(board, required_length):
  Loop:
    Đọc 4 số vào row_b, col_b, row_s, col_s
    Nếu parse thất bại: in lỗi, tiếp tục loop
    
    Nếu có tọa độ < 0 hoặc > 6: in lỗi, tiếp tục loop
    
    Nếu (row_b ≠ row_s) XOR (col_b ≠ col_s) = false: in lỗi, tiếp tục loop
    
    computed_length = max(|row_s - row_b|, |col_s - col_b|) + 1
    Nếu computed_length ≠ required_length: in lỗi, tiếp tục loop
    
    Duyệt từ điểm nhỏ đến điểm lớn của tàu:
      Nếu board[hàng][cột] ≠ 0: in lỗi, tiếp tục loop
    
    # Nếu đến đây, tàu hợp lệ
    Ghi 1 vào tất cả ô của tàu
    Thông báo thành công
    Thoát loop
```

---

## 7. THUẬT TOÁN GIAI ĐOẠN BATTLE

### 7.1 Battle Loop chung

Vòng lặp battle lặp lại cho đến khi một player thắng:

**Cho mỗi lượt tấn công:**

1. **Hiển thị bàn cờ:** In board của người chơi hiện tại và enemy map (bản ghi bắn đối phương)

2. **Nhập tọa độ mục tiêu:**
   - Hiển thị prompt
   - Đọc hai số: row, col
   - Gọi parse_two_ints

3. **Kiểm tra hợp lệ:**
   - Verify: 0 ≤ row, col ≤ 6
   - Nếu sai → thông báo lỗi, yêu cầu nhập lại

4. **Chuyển đổi tọa độ thành chỉ số:**
   - `index = row × 7 + col`
   - `byte_offset = index × 4`

5. **Kiểm tra bắn lại:**
   - Kiểm tra memory board của người chơi tại byte_offset
   - Nếu ≠ 0 (tức là đã bắn rồi) → thông báo "Already targeted", yêu cầu nhập lại

6. **Kiểm tra hit/miss:**
   - **Hit:** Nếu opponent_board[byte_offset] == 1
     - Ghi 0 vào opponent_board[byte_offset] (phá hủy tàu)
     - Ghi 2 vào memory_board[byte_offset] (ghi nhận hit)
     - In "HIT!"
   
   - **Miss:** Nếu opponent_board[byte_offset] == 0
     - Ghi 1 vào memory_board[byte_offset] (ghi nhận miss)
     - In "MISS!"

7. **Kiểm tra điều kiện thắng:**
   - Gọi board_has_ship(opponent_board)
   - Nếu trả về false (không còn ship nào) → người chơi hiện tại thắng
   - Nếu còn ship → chuyển lượt cho người chơi tiếp theo

### 7.2 Hàm board_has_ship

Thủ tục này duyệt qua 49 ô của board:
- Nếu tìm thấy ô nào có giá trị 1 → trả về true (còn tàu)
- Nếu không tìm thấy ô nào có 1 → trả về false (không còn tàu)

---

## 8. CHẾ ĐỘ ONE PLAYER VÀ COMPUTER

### 8.1 Setup Computer

Thay vì yêu cầu người chơi 2 đặt tàu, chương trình tự động load template từ `autoBoardTemplate`:
- Là mảng 49 giá trị được hardcode
- Chứa cấu hình tàu cố định (3 tàu dài 2, 2 tàu dài 3, 1 tàu dài 4)
- Được copy vào boardP2 bằng thủ tục load_auto_board

### 8.2 Computer Attack

Thủ tục computer_attack triển khai chiến lược tấn công đơn giản:
1. Duyệt từ chỉ số 0 đến 48 của memP2 (bản ghi bắn của Computer)
2. Tìm chỉ số đầu tiên có giá trị 0 (chưa bắn)
3. Thực hiện tấn công vào ô đó như một người chơi thường
4. Cập nhật memP2 và boardP1 tương ứng
5. Thông báo kết quả

**Lưu ý:** Chiến lược này là đơn giản, dễ kiểm thử, không phải AI nâng cao. Để cải tiến, có thể thêm randomization hoặc "hunting" dựa trên các hit trước đó.

---

## 9. PHÂN TÍCH VÀ VALIDATION INPUT

### 9.1 Thủ tục parse_four_ints

Đọc chuỗi từ inputBuffer và tách thành bốn số nguyên:
- **Cách hoạt động:** Duyệt ký tự, bỏ qua khoảng trắng, tích lũy các chữ số thành số
- **Output:** Bốn số được lưu vào các thanh ghi (thường $t0, $t1, $t2, $t3)
- **Trả về:** $v0 = 1 nếu parse thành công, = 0 nếu thất bại (ít hơn 4 số)

### 9.2 Thủ tục parse_two_ints

Tương tự parse_four_ints nhưng chỉ tách hai số:
- **Output:** Hai số vào $t0, $t1
- **Trả về:** $v0 = 1 nếu thành công, = 0 nếu thất bại

### 9.3 Chính sách xác thực

- Chương trình chỉ chấp nhận các số không âm phù hợp với tọa độ [0, 6]
- Input sai định dạng (ít/nhiều số hơn mong đợi, ký tự không phải số) bị từ chối
- Input tọa độ ngoài phạm vi [0, 6] bị từ chối
- Người dùng phải nhập lại cho đến khi hợp lệ

---

## 10. TỔ CHỨC THỦ TỤC VÀ KHÁI NIỆM MIPS

### 10.1 Danh sách các thủ tục chính

| Thủ tục | Chức năng |
|---------|----------|
| main | Điều phối menu, chọn mode, gọi setup/battle |
| show_menu | Hiển thị menu chính, trả về lựa chọn |
| show_help | Hiển thị hướng dẫn cách chơi |
| choose_game_mode | Lựa chọn One/Two players |
| clear_board | Đặt 49 phần tử board thành 0 |
| setup_player | Yêu cầu người chơi đặt 6 tàu |
| read_and_place_ship | Đọc, validate, đặt một tàu |
| parse_four_ints | Tách 4 số từ chuỗi |
| parse_two_ints | Tách 2 số từ chuỗi |
| print_board | In một board đơn |
| print_dual_boards | In song song board riêng + enemy map |
| board_has_ship | Kiểm tra board còn tàu |
| load_auto_board | Copy template cho Computer |
| computer_attack | Computer tấn công |
| game_loop | Vòng lặp battle chính |
| pause_for_swap | Tạm dừng để đổi lượt (Two Players) |

### 10.2 Cơ chế gọi procedure

- **jal (Jump And Link):** Gọi procedure, lưu địa chỉ trả về vào $ra
- **jr (Jump Register):** Quay lại từ procedure (jr $ra)

### 10.3 Bảo toàn thanh ghi (Register Preservation)

Các procedure phức tạp (đặc biệt là setup_player, print_dual_boards) thường:
- Lưu $ra lên stack ngay khi bắt đầu (để bảo vệ nếu có gọi procedure con)
- Lưu các thanh ghi $s0, $s1, ... dùng trong procedure
- Khôi phục tất cả khi thoát

**Ví dụ cấu trúc:**
```
save_regs:
  addi $sp, $sp, -16
  sw $ra, 0($sp)
  sw $s0, 4($sp)
  ...

[body of procedure]

restore_regs:
  lw $ra, 0($sp)
  lw $s0, 4($sp)
  ...
  addi $sp, $sp, 16
  jr $ra
```

### 10.4 MIPS Syscalls được dùng

| Syscall # | Chức năng | Tham số |
|-----------|----------|---------|
| 1 | Print integer | $a0 = số |
| 4 | Print string | $a0 = địa chỉ chuỗi |
| 5 | Read integer | Trả về vào $v0 |
| 8 | Read string | $a0 = buffer, $a1 = kích thước |
| 10 | Exit | (không tham số) |

### 10.5 Branch và Jump

- **beq, bne, bltz, bgez, ...:** Điều khiển vòng lặp, kiểm tra điều kiện
- **j, jal, jr:** Nhảy vô điều kiện, gọi procedure, trả về

---

## 11. THIẾT KẾ GIAO DIỆN NGƯỜI DÙNG

### 11.1 Menu chính

Chương trình bắt đầu bằng menu:
```
=== BATTLESHIP ===
1. Play Game
2. Instructions
3. Quit
Enter your choice (1, 2 or 3):
```

### 11.2 Màn hình hướng dẫn

Hiển thị:
- Fleet composition
- Setup instructions (format: row_bow col_bow row_stern col_stern)
- Battle instructions (format: row col)
- Giải thích HIT/MISS
- Điều kiện thắng

### 11.3 Hiển thị dual board

Khi player tấn công, chương trình in:
- **Bên trái:** Board của người chơi (với ký hiệu 1, ., X, O)
- **Bên phải:** Enemy Map (với ký hiệu ., O, X)

Ví dụ:
```
Your board           Enemy map
   0 1 2 3 4 5 6        0 1 2 3 4 5 6
0: 1 . . . . . .      0: . . . . . . .
1: 1 1 . . . . .      1: . O . . . . .
2: . . . . . . .      2: . X . . . . .
...
```

### 11.4 Thông báo và ghi chú

- **Successful ship:** "Ship placed successfully"
- **Invalid ship:** "Invalid ship. Re-enter"
- **HIT:** "HIT!"
- **MISS:** "MISS!"
- **Repeated attack:** "This cell was already targeted. Choose another"
- **Winner:** "PLAYER 1 WINS!" hoặc "PLAYER 2 WINS!"
- **Two-player pause:** "(Press Enter and give control to the other player)"

### 11.5 Tính năng bảo mật (Two Players)

Thủ tục pause_for_swap yêu cầu Enter để đổi lượt. Điều này giúp ngăn ngừa người chơi nhìn thấy board của đối thủ khi người khác không chú ý.

---

## 12. KẾ HOẠCH KIỂM THỬ VÀ CÁC TRƯỜNG HỢP KIỂM THỬ

### 12.1 Bảng test case

| # | Test Case | Input/Hành động | Kết quả mong đợi | Mục đích |
|---|-----------|-----------------|------------------|---------|
| 1 | Đặt tàu ngang hợp lệ | Tàu dài 3: (1, 0, 1, 2) | Ship placed successfully | Validate placement ngang |
| 2 | Đặt tàu dọc hợp lệ | Tàu dài 2: (0, 3, 1, 3) | Ship placed successfully | Validate placement dọc |
| 3 | Tàu ngoài biên (hàng) | Tàu dài 2: (7, 0, 7, 1) | Invalid ship | Reject ngoài phạm vi |
| 4 | Tàu ngoài biên (cột) | Tàu dài 2: (0, 7, 0, 8) | Invalid ship | Reject ngoài phạm vi |
| 5 | Tàu sai độ dài | Request dài 4: (0, 0, 0, 2) | Invalid ship | Validate độ dài |
| 6 | Tàu chéo | Tàu: (0, 0, 1, 1) | Invalid ship | Reject không ngang/dọc |
| 7 | Tàu overlap | Đặt lần 2 ở ô đã có tàu | Invalid ship | Reject chồng lấn |
| 8 | Bắn trúng (HIT) | Bắn vào ô có tàu | HIT! + cập nhật board | Validate hit detection |
| 9 | Bắn hụt (MISS) | Bắn vào ô trống | MISS! + cập nhật memory | Validate miss detection |
| 10 | Bắn lại ô đã bắn | Bắn ô (2, 3) hai lần | Rejected message lần 2 | Prevent repeated shot |
| 11 | Game kết thúc | Phá hủy hết tàu đối thủ | "PLAYER X WINS!" | Validate win condition |
| 12 | One Player mode | Chọn mode 1, Computer tự setup | Computer board loaded | Verify auto board loading |
| 13 | Two Players mode | Chọn mode 2, Player 2 setup | P2 input được nhận | Verify two-player setup |
| 14 | Menu Instructions | Chọn option 2 | Hiển thị help text | Verify help display |
| 15 | Menu Quit | Chọn option 3 | Thoát chương trình | Verify graceful exit |

### 12.2 Quy trình kiểm thử

1. **Kiểm thử setup phase:**
   - Đặt các tàu hợp lệ (ngang, dọc, biên)
   - Kiểm tra từ chối input không hợp lệ (ngoài biên, sai độ dài, chéo, overlap)

2. **Kiểm thử battle phase:**
   - Bắn vào các ô khác nhau (hit, miss)
   - Kiểm tra không bắn lại ô đã bắn
   - Bắn hết tàu đối thủ → kiểm tra thắng

3. **Kiểm thử menu và chế độ:**
   - Play game, Instructions, Quit
   - One Player vs Two Players
   - Pause for swap (Two Players)

---

## 13. GIỚI HẠN VÀ CÓ THỂ CẢI TIẾN

### 13.1 Giới hạn hiện tại

1. **Computer AI đơn giản:** Bắn theo thứ tự tuyến tính từ ô 0 đến 48, không có chiến lược thông minh
2. **Board cố định:** Kích thước 7×7 được hardcode, không thể thay đổi
3. **Không ghi log:** Chương trình không lưu lịch sử nước đi ra file
4. **Input parsing cơ bản:** Không xử lý số âm, format phức tạp, dấu cách thừa
5. **Không randomize Computer:** Tàu Computer luôn ở vị trí giống nhau

### 13.2 Những cải tiến khả thi

1. **Random computer attack:** Sử dụng pseudorandom để Computer chọn ô ngẫu nhiên
2. **Smart AI hunting:** Nếu hit, Computer tập trung bắn ô xung quanh
3. **Move history logging:** Lưu lịch sử nước đi vào file .txt
4. **Configurable board size:** Cho phép chọn board 7×7, 10×10, v.v.
5. **Better input validation:** Xử lý các format input khác nhau, số âm
6. **Animated graphics:** Thêm ký tự màu, clearing screen giữa lượt
7. **Replay mode:** Lưu/tái tạo một ván đã chơi

---

## 14. KẾT LUẬN

### 14.1 Tóm tắt thực hiện

Chương trình đã mô phỏng đầy đủ trò chơi Battleship trên bàn cờ 7×7 bằng MIPS Assembly trong MARS. Các thành phần chính bao gồm:

- **Setup phase:** Validation đầy đủ cho placement tàu (phạm vi, hướng, độ dài, no overlap)
- **Battle phase:** Hit/miss detection, repeated shot prevention, win condition checking
- **Dual game modes:** One Player (vs Computer) và Two Players
- **Menu system:** Main menu, Instructions, mode selection
- **UI:** Dual board display, clear messages, pause for player swap (two-player)

### 14.2 Kỹ năng MIPS áp dụng

Assignment này rèn luyện:
- **Memory addressing:** Array indexing (row × 7 + col), byte offset calculation
- **Arithmetic:** Tính toán độ dài tàu, tọa độ
- **Branch/Jump:** Vòng lặp, điều kiện kiểm tra, multi-way selection
- **Procedure calls:** Modular design với jal/jr, stack frame management
- **Register preservation:** Saving $ra, $s registers trên stack
- **System calls:** String I/O, integer I/O, program flow control

### 14.3 Đánh giá chất lượng

Chương trình:
- ✓ Đầy đủ tính năng theo yêu cầu
- ✓ Rõ ràng, dễ đọc nhờ modular design
- ✓ Validation input cẩn thận
- ✓ Xử lý edge case (ngoài biên, overlap, repeated attack)
- ✓ Giao diện thân thiện, thông báo rõ
- ✓ Hỗ trợ cả One/Two Player modes

### 14.4 Kết luận cuối

Thông qua assignment này, sinh viên đã:
1. Triển khai một trò chơi tương tác phức tạp bằng MIPS Assembly
2. Luyện tập quản lý bộ nhớ, điều kiện rẽ nhánh, gọi procedure
3. Hiểu sâu về cách hoạt động của MARS simulator
4. Áp dụng nguyên tắc thiết kế phần mềm (modular, validation, clear messages) vào Assembly

Assignment Battleship là bước đệm quan trọng để hiểu Computer Architecture ở mức độ sâu hơn.

---

## 15. PHỤ LỤC

### Phụ lục A: Danh sách toàn bộ procedures

1. **main** - Điều phối chương trình
2. **show_menu** - Menu chính
3. **show_help** - Hướng dẫn
4. **choose_game_mode** - Chọn chế độ chơi
5. **clear_board** - Xóa board thành 0
6. **setup_player** - Setup 6 tàu
7. **read_and_place_ship** - Đặt một tàu
8. **parse_four_ints** - Tách 4 số
9. **parse_two_ints** - Tách 2 số
10. **print_board** - In board
11. **print_dual_boards** - In dual board
12. **board_has_ship** - Kiểm tra còn tàu
13. **load_auto_board** - Load template
14. **computer_attack** - Computer tấn công
15. **game_loop** - Vòng lặp battle
16. **pause_for_swap** - Tạm dừng

### Phụ lục B: Công thức chính

```
Board index = row × 7 + column (0 ≤ row, col ≤ 6)
Byte offset = index × 4
Ship length = max(|row_stern - row_bow|, |col_stern - col_bow|) + 1
```

### Phụ lục C: Ký hiệu hiển thị

| Ký hiệu | Ý nghĩa (Own board) | Ý nghĩa (Enemy map) |
|---------|---------------------|-------------------|
| 1 | Tàu | N/A |
| . | Ô trống | Unknown |
| X | Tàu bị phá | Hit |
| O | Bắn vào ô trống | Miss |

---

**Báo cáo này hoàn thành theo đúng yêu cầu của Assignment Battleship, môn CO2008 Computer Architecture Lab.**

