// 自転車用安全フラッグの棒（ポール）コネクター
// 径の異なる2本の棒（5.5mmと6.0mm）を接続します

/* [基本設定] */
// 1本目の棒の径 (mm)
pole1_diameter = 5.5; 
// 2本目の棒の径 (mm)
pole2_diameter = 6.0; 
// はめ込みの余裕（プリンタの精度に合わせて調整してください）
tolerance = 0.5; 

/* [詳細設定] */
// 差し込み口の肉厚 (mm)
wall_end = 1.2;
// 中央部の肉厚 (mm)
wall_center = 2.0;
// 各ポールの差し込み深さ (mm)
insertion_depth = 25.0;
// 中央のストッパー（仕切り）の厚み (mm)
stop_thickness = 5.0;

/* [レンダリング設定] */
// 円の細かさ
$fn = 100;

// --- 計算値 ---
d1 = pole1_diameter + tolerance;
d2 = pole2_diameter + tolerance;
// 端部と中央部の外径を計算
outer_d1_end = d1 + (wall_end * 2);
outer_d2_end = d2 + (wall_end * 2);
outer_d_center = max(d1, d2) + (wall_center * 2);
total_length = (insertion_depth * 2) + stop_thickness;

module flag_connector() {
    difference() {
        // 外形（メインボディ：中央に向かって太くなる形状）
        hull() {
            // 下端
            translate([0, 0, -total_length/2])
                cylinder(h = 0.1, d = outer_d1_end);
            // 中央部
            cylinder(h = stop_thickness, d = outer_d_center, center = true);
            // 上端
            translate([0, 0, total_length/2 - 0.1])
                cylinder(h = 0.1, d = outer_d2_end);
        }

        // 下側の穴 (Pole 1: 5.5mm用)
        translate([0, 0, -total_length/2 - 0.1])
            cylinder(h = insertion_depth + 0.1, d = d1);

        // 上側の穴 (Pole 2: 6.0mm用)
        translate([0, 0, stop_thickness/2])
            cylinder(h = insertion_depth + 0.1, d = d2);
            
        // オプション: どちらが太い方か分かるように目印（小さな面取りなど）
        // ここでは単純なシリンダー形状にしています
    }
}

// 実行
flag_connector();

// プレビュー用に横にポールのダミーを表示（レンダリング時は無視されます）
% translate([0, 0, stop_thickness/2 + 5]) cylinder(h = 30, d = pole2_diameter);
% translate([0, 0, -stop_thickness/2 - 35]) cylinder(h = 30, d = pole1_diameter);
