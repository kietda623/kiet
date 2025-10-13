#!/bin/bash

# ===============================
# 🎮 Trò chơi Đi Tìm Triệu Phú (FIX LỖI VÒNG LẶP TRIỆT ĐỂ)
# ===============================

CAUHOI_FILE="cauhoi.txt"
TRALOI_FILE="traloi.txt"
SO_CAU=10
# $TIEN_THUONG[i] là tiền thưởng NHẬN được khi trả lời đúng câu i
TIEN_THUONG=(0 1000 2000 5000 10000 20000 40000 80000 160000 320000 640000)
giup_5050=1

# Tên file tạm
TEMP_FILE="temp_questions.txt"

# ===============================
# 1️⃣ Kiểm tra file dữ liệu
# ===============================
if [ ! -f "$CAUHOI_FILE" ] || [ ! -f "$TRALOI_FILE" ]; then
    echo "⚠️ Chưa có file cauhoi.txt hoặc traloi.txt!"
    echo "Tạo file cauhoi.txt và traloi.txt trước khi chạy."
    exit 1
fi

# ===============================
# 2️⃣ Chuẩn bị và làm sạch dữ liệu
# ===============================
echo "============================================"
echo "         🎉 CHÀO MỪNG BẠN ĐẾN VỚI TRÒ CHƠI"
echo "           👉  ĐI TÌM TRIỆU PHÚ 👈"
echo "============================================"

# Lấy ngẫu nhiên 10 câu hỏi, LỌC BỎ ký tự \r (CRLF) và dòng trống
# => Đảm bảo file tạm SẠCH sẽ cho read
shuf -n "$SO_CAU" "$CAUHOI_FILE" | tr -d '\r' | grep -v '^$' > "$TEMP_FILE"

# Lấy số câu hỏi thực tế sau khi làm sạch
ACTUAL_SO_CAU=$(wc -l < "$TEMP_FILE")

if [ "$ACTUAL_SO_CAU" -eq 0 ]; then
    echo "⚠️ Không tìm thấy câu hỏi nào hợp lệ để chơi!"
    rm -f "$TEMP_FILE"
    exit 1
fi

if [ "$ACTUAL_SO_CAU" -lt "$SO_CAU" ]; then
    echo "⚠️ Chỉ tìm được $ACTUAL_SO_CAU câu hỏi. Trò chơi sẽ kết thúc sớm hơn."
    SO_CAU=$ACTUAL_SO_CAU
fi

so_cau=0
diem=0 # Số câu trả lời đúng (dùng làm index cho tiền thưởng)

# ===============================
# 3️⃣ Bắt đầu vòng chơi
# ===============================
# **FIX LỖI:** Dùng `exec` để mở file trên descriptor 3 và đọc
# Điều này cô lập vòng lặp `while` khỏi các lệnh `read` khác trong script.
exec 3< "$TEMP_FILE"

while IFS="|" read -u 3 -r ma noidung A B C D; do
    
    # Kiểm tra xem đã đủ số câu tối đa chưa (Dù file đã sạch, vẫn nên có)
    if [ "$so_cau" -ge "$SO_CAU" ]; then
        break
    fi

    ((so_cau++))

    # Lấy đáp án đúng từ TRALOI_FILE
    dapan_dung=$(grep "^$ma|" "$TRALOI_FILE" | cut -d"|" -f2)
    
    # Kiểm tra nếu không tìm thấy đáp án
    if [ -z "$dapan_dung" ]; then
        echo "Lỗi: Không tìm thấy đáp án cho câu hỏi $ma. Bỏ qua câu này." >&2
        ((so_cau--)) 
        continue
    fi
    
    # Hiển thị câu hỏi
    echo ""
    echo "--------------------------------------------"
    echo "🧩 Câu $so_cau/$SO_CAU: $noidung"
    echo "$A"
    echo "$B"
    echo "$C"
    echo "$D"
    echo "--------------------------------------------"
    echo "💰 Tiền thưởng câu này: ${TIEN_THUONG[$so_cau]}$ (Đang có: ${TIEN_THUONG[$((so_cau-1))]}$)"
    echo "🎁 Trợ giúp 50/50: $( [ $giup_5050 -eq 1 ] && echo ✅ || echo ❌ )"
    echo "--------------------------------------------"

    # Vòng lặp nhập đáp án/trợ giúp
    while true; do
        echo -n "👉 Nhập đáp án (A/B/C/D) hoặc '50' để dùng 50/50: "
        read dapan
        dapan=$(echo "$dapan" | tr '[:lower:]' '[:upper:]')

        # --- Quyền trợ giúp 50/50 ---
        if [ "$dapan" == "50" ]; then
            if [ $giup_5050 -eq 1 ]; then
                giup_5050=0
                all=("A" "B" "C" "D")
                sai=($(printf "%s\n" "${all[@]}" | grep -v "$dapan_dung" | shuf -n 2))
                echo "💡 50/50: Hai đáp án bị loại là: ${sai[*]}"
                continue
            else
                echo "⚠️ Bạn đã dùng trợ giúp 50/50 rồi!"
                continue
            fi
        fi

        # --- Kiểm tra đáp án ---
        if [[ "$dapan" =~ ^[ABCD]$ ]]; then
            if [ "$dapan" == "$dapan_dung" ]; then
                # TRẢ LỜI ĐÚNG
                diem=$so_cau
                echo "✅ Chính xác! Bạn nhận được ${TIEN_THUONG[$diem]}$."
                break
            else
                # TRẢ LỜI SAI
                echo "❌ Sai rồi! Đáp án đúng là $dapan_dung."
                echo "💸 Bạn ra về với ${TIEN_THUONG[$diem]}$."
                exec 3<&- # Đóng file descriptor
                rm -f "$TEMP_FILE"
                exit 0
            fi
        else
            echo "⚠️ Vui lòng nhập A, B, C, D hoặc 50."
        fi
    done

    # Kiểm tra nếu đã hoàn thành tất cả các câu hỏi
    if [ "$so_cau" -eq "$SO_CAU" ]; then
        echo ""
        echo "🎉 Chúc mừng! Bạn đã trả lời đúng toàn bộ $SO_CAU câu!"
        echo "💰 Tổng tiền thưởng: ${TIEN_THUONG[$diem]}$"
        break # Thoát vòng lặp chính
    fi

done

# Dọn dẹp cuối cùng
exec 3<&- # Đảm bảo file descriptor được đóng
rm -f "$TEMP_FILE"
exit 0