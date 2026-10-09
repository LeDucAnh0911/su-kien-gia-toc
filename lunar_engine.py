"""
Lõi thuật toán Âm Lịch Việt Nam (Vietnamese Lunar Calendar Engine)
Dựa trên thuật toán thiên văn học của TS. Hồ Ngọc Đức (Múi giờ GMT+7 Việt Nam).
Bao gồm:
- Chuyển đổi Dương lịch <-> Âm lịch.
- Tính Can Chi của Ngày, Tháng, Năm.
- Tính ngày giỗ kế tiếp theo Dương lịch (xử lý chuẩn tháng thiếu 29 ngày và tháng nhuận).
"""

import math
import sys
from datetime import date, datetime, timedelta

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

# Bảng Thiên Can và Địa Chi
CAN = ["Giáp", "Ất", "Bính", "Đinh", "Mậu", "Kỷ", "Canh", "Tân", "Nhâm", "Quý"]
CHI = ["Tý", "Sửu", "Dần", "Mão", "Thìn", "Tỵ", "Ngọ", "Mùi", "Thân", "Dậu", "Tuất", "Hợi"]

def jd_from_date(day: int, month: int, year: int) -> int:
    """Tính số ngày Julius (Julian Day Number) từ ngày Dương lịch."""
    a = (14 - month) // 12
    y = year + 4800 - a
    m = month + 12 * a - 3
    jd = day + ((153 * m + 2) // 5) + 365 * y + (y // 4) - (y // 100) + (y // 400) - 32045
    return jd

def jd_to_date(jd: int):
    """Chuyển số ngày Julius sang ngày Dương lịch (ngày, tháng, năm)."""
    a = jd + 32044
    b = (4 * a + 3) // 146097
    c = a - (146097 * b) // 4
    d = (4 * c + 3) // 1461
    e = c - (1461 * d) // 4
    m = (5 * e + 2) // 153
    day = e - ((153 * m + 2) // 5) + 1
    month = m + 3 - 12 * (m // 10)
    year = 100 * b + d - 4800 + (m // 10)
    return day, month, year

def get_new_moon_day(k: int, timezone: float = 7.0) -> int:
    """Tính ngày Sóc (New Moon) theo múi giờ chỉ định."""
    t = k / 1236.85
    t2 = t * t
    t3 = t2 * t
    jd1 = 2415020.75933 + 29.53058868 * k + 0.0001178 * t2 - 0.000000155 * t3
    
    # Góc lệch Mặt Trời
    m = 359.2242 + 29.10535608 * k - 0.0000333 * t2 - 0.00000347 * t3
    m_rad = math.radians(m)
    
    # Góc lệch Mặt Trăng
    mprime = 306.0253 + 385.81691806 * k + 0.0107306 * t2 + 0.00001236 * t3
    mprime_rad = math.radians(mprime)
    
    # Góc khoảng cách Mặt Trăng
    f = 21.2964 + 390.67050646 * k - 0.0016528 * t2 - 0.00000239 * t3
    f_rad = math.radians(f)
    
    delta_jd = (
        (0.1734 - 0.000393 * t) * math.sin(m_rad)
        + 0.0021 * math.sin(2 * m_rad)
        - 0.4068 * math.sin(mprime_rad)
        + 0.0161 * math.sin(2 * mprime_rad)
        - 0.0004 * math.sin(3 * mprime_rad)
        + 0.0104 * math.sin(2 * f_rad)
        - 0.0051 * math.sin(m_rad + mprime_rad)
        - 0.0074 * math.sin(m_rad - mprime_rad)
        + 0.0004 * math.sin(2 * f_rad + m_rad)
        - 0.0004 * math.sin(2 * f_rad - m_rad)
        - 0.0006 * math.sin(2 * f_rad + mprime_rad)
        + 0.0010 * math.sin(2 * f_rad - mprime_rad)
        + 0.0005 * math.sin(m_rad + 2 * mprime_rad)
    )
    
    jd = jd1 + delta_jd
    return int(jd + 0.5 + timezone / 24.0)

def get_sun_longitude(jdn: int, timezone: float = 7.0) -> int:
    """Tính kinh độ Mặt Trời (đơn vị cung hoàng đạo, 0..11)."""
    t = (jdn - 0.5 - timezone / 24.0 - 2451545.0) / 36525.0
    t2 = t * t
    dr = math.pi / 180.0
    
    # Kinh độ trung bình
    l0 = 280.46645 + 36000.76983 * t + 0.0003032 * t2
    # Độ bất thường trung bình
    m = 357.52910 + 35999.05030 * t - 0.0001559 * t2 - 0.00000048 * t * t2
    
    c = (
        (1.914600 - 0.004817 * t - 0.000014 * t2) * math.sin(m * dr)
        + (0.019993 - 0.000101 * t) * math.sin(2 * m * dr)
        + 0.000290 * math.sin(3 * m * dr)
    )
    theta = l0 + c
    theta = theta % 360.0
    return int(theta / 30.0)

def get_lunar_month11(year: int, timezone: float = 7.0) -> int:
    """Tìm ngày Sóc của tháng 11 Âm lịch của năm chỉ định (tháng có Đông chí)."""
    off = jd_from_date(31, 12, year) - 2415021
    k = int(off / 29.530588853)
    nm = get_new_moon_day(k, timezone)
    sun_long = get_sun_longitude(nm, timezone)
    if sun_long >= 9:
        nm = get_new_moon_day(k - 1, timezone)
    return nm

def get_leap_month_offset(a11: int, timezone: float = 7.0) -> int:
    """Xác định xem có tháng nhuận sau tháng 11 âm lịch hay không."""
    k = int((a11 - 2415021.076998695) / 29.530588853 + 0.5)
    last = 0
    i = 1
    arc = get_sun_longitude(get_new_moon_day(k + i, timezone), timezone)
    while True:
        last = arc
        i += 1
        arc = get_sun_longitude(get_new_moon_day(k + i, timezone), timezone)
        if arc == last or i >= 14:
            break
    return i - 1

def convert_solar_to_lunar(day: int, month: int, year: int, timezone: float = 7.0):
    """Chuyển đổi ngày Dương lịch sang Âm lịch Việt Nam."""
    day_number = jd_from_date(day, month, year)
    k = int((day_number - 2415021.076998695) / 29.530588853)
    month_start = get_new_moon_day(k + 1, timezone)
    if month_start > day_number:
        month_start = get_new_moon_day(k, timezone)
    
    a11 = get_lunar_month11(year, timezone)
    b11 = a11
    if a11 >= month_start:
        lunar_year = year
        a11 = get_lunar_month11(year - 1, timezone)
    else:
        lunar_year = year + 1
        b11 = get_lunar_month11(year + 1, timezone)
        
    lunar_day = day_number - month_start + 1
    diff = int((month_start - a11) / 29.0)
    lunar_leap = 0
    lunar_month = diff + 11
    
    if (b11 - a11) > 365:
        leap_off = get_leap_month_offset(a11, timezone)
        leap_month = leap_off - 2
        if leap_month < 0:
            leap_month += 12
        if diff >= leap_off:
            lunar_month = diff + 10
            if diff == leap_off:
                lunar_leap = 1
                
    if lunar_month > 12:
        lunar_month -= 12
    if lunar_month >= 11 and diff < 4:
        lunar_year -= 1
        
    return {
        "day": lunar_day,
        "month": lunar_month,
        "year": lunar_year,
        "is_leap": bool(lunar_leap),
        "jd": day_number
    }

def convert_lunar_to_solar(lunar_day: int, lunar_month: int, lunar_year: int, is_leap: bool = False, timezone: float = 7.0):
    """Chuyển đổi ngày Âm lịch sang Dương lịch Việt Nam."""
    if lunar_month < 11:
        a11 = get_lunar_month11(lunar_year - 1, timezone)
        b11 = get_lunar_month11(lunar_year, timezone)
    else:
        a11 = get_lunar_month11(lunar_year, timezone)
        b11 = get_lunar_month11(lunar_year + 1, timezone)
        
    k = int((a11 - 2415021.076998695) / 29.530588853 + 0.5)
    off = lunar_month - 11
    if off < 0:
        off += 12
        
    if (b11 - a11) > 365:
        leap_off = get_leap_month_offset(a11, timezone)
        leap_month = leap_off - 2
        if leap_month < 0:
            leap_month += 12
        if is_leap and (lunar_month != leap_month):
            return None # Không có tháng nhuận này
        if (off >= leap_off - 1) or is_leap:
            off += 1
            
    month_start = get_new_moon_day(k + off, timezone)
    return jd_to_date(month_start + lunar_day - 1)

def get_can_chi_year(lunar_year: int) -> str:
    """Tính Can Chi của năm Âm lịch."""
    can = CAN[(lunar_year + 6) % 10]
    chi = CHI[(lunar_year + 8) % 12]
    return f"{can} {chi}"

def get_can_chi_day(jd: int) -> str:
    """Tính Can Chi của ngày theo số ngày Julius."""
    can = CAN[(jd + 9) % 10]
    chi = CHI[(jd + 1) % 12]
    return f"{can} {chi}"

def get_lunar_month_days(lunar_month: int, lunar_year: int) -> int:
    """Xác định tháng âm có 29 hay 30 ngày (tháng thiếu hay tháng đủ)."""
    res30 = convert_lunar_to_solar(30, lunar_month, lunar_year, is_leap=False)
    if res30:
        back = convert_solar_to_lunar(res30[0], res30[1], res30[2])
        if back["month"] == lunar_month and back["day"] == 30:
            return 30
    return 29

def get_next_death_anniversary(
    lunar_day: int, 
    lunar_month: int, 
    from_solar_date: date = None
):
    """
    Tính ngày giỗ tiếp theo (theo Dương lịch) từ một mốc thời gian cụ thể.
    Xử lý:
    - Tháng thiếu: Nếu người mất ngày 30 mà tháng đó năm nay chỉ có 29 ngày, tự động cúng ngày 29.
    - So sánh với ngày hiện tại: Nếu giỗ năm nay đã qua thì tính ngày giỗ năm sau.
    """
    if from_solar_date is None:
        from_solar_date = date.today()
        
    current_solar_year = from_solar_date.year
    
    # Duyệt trong các năm âm lịch lân cận (năm nay và năm sau)
    for year_cand in [current_solar_year, current_solar_year + 1]:
        # Xử lý tháng thiếu: nếu ngày giỗ là 30 nhưng tháng đó chỉ có 29 ngày
        max_days = get_lunar_month_days(lunar_month, year_cand)
        target_day = min(lunar_day, max_days)
        
        res = convert_lunar_to_solar(target_day, lunar_month, year_cand, is_leap=False)
        if res:
            solar_res = date(res[2], res[1], res[0])
            if solar_res >= from_solar_date:
                days_remaining = (solar_res - from_solar_date).days
                tieng_thuong_date = solar_res - timedelta(days=1)
                return {
                    "chinh_ky_solar": solar_res,
                    "tieng_thuong_solar": tieng_thuong_date,
                    "days_remaining": days_remaining,
                    "adjusted_lunar_day": target_day,
                    "original_lunar_day": lunar_day,
                    "lunar_month": lunar_month,
                    "lunar_year": year_cand,
                    "can_chi_year": get_can_chi_year(year_cand)
                }
            
    return None

if __name__ == "__main__":
    today = date.today()
    print(f"Hôm nay (Dương lịch): {today.strftime('%d/%m/%Y')}")
    lunar_today = convert_solar_to_lunar(today.day, today.month, today.year)
    jd = jd_from_date(today.day, today.month, today.year)
    print(f"Âm lịch: Ngày {lunar_today['day']} tháng {lunar_today['month']} năm {get_can_chi_year(lunar_today['year'])} ({lunar_today['year']})")
    print(f"Can Chi ngày: {get_can_chi_day(jd)}")
    
    # Test tính ngày giỗ Cụ Ông vào 15/8 Âm Lịch (Rằm Trung Thu)
    gio_1 = get_next_death_anniversary(15, 8, today)
    print("\n--- Test Ngày Giỗ 1: 15/8 Âm lịch ---")
    if gio_1:
        print(f"Chính kỵ (Dương lịch): {gio_1['chinh_ky_solar'].strftime('%d/%m/%Y')}")
        print(f"Tiên thường (Chiều hôm trước): {gio_1['tieng_thuong_solar'].strftime('%d/%m/%Y')}")
        print(f"Số ngày còn lại: {gio_1['days_remaining']} ngày")
    
    # Test ngày mất vào 30 tháng Chạp (Tháng 12 Âm) - kiểm tra tháng thiếu
    print("\n--- Test Ngày Giỗ 2: 30/12 Âm lịch (Kiểm tra xử lý tháng thiếu) ---")
    gio_2 = get_next_death_anniversary(30, 12, today)
    if gio_2:
        print(f"Chính kỵ (Dương lịch): {gio_2['chinh_ky_solar'].strftime('%d/%m/%Y')} (Cúng ngày {gio_2['adjusted_lunar_day']}/{gio_2['lunar_month']} Âm)")
        print(f"Tiên thường: {gio_2['tieng_thuong_solar'].strftime('%d/%m/%Y')}")
        print(f"Số ngày còn lại: {gio_2['days_remaining']} ngày")
