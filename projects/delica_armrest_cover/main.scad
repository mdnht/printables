// デリカD5 アームレスト穴埋め蓋（ドーム型キャップ・スプライン付き）

/* [キャップの設定] */
cap_diameter = 70;    // 蓋の直径
cap_height = 2.5;       // 蓋の中央の厚み（ドームの高さ）

/* [軸・穴の設定] */
hole_diameter = 18.0;   // 穴の最大外径 (18mm)
plug_length = 20.0;     // 差し込み部分の全長

/* [固定ピン用の溝設定] */
// 蓋の裏面から溝の中心までの距離（現物に合わせて要調整）
groove_offset = 4.0;   
groove_width = 2.0;     // 溝の幅
groove_inner_dia = 14; // 溝の底の直径

/* [歯車状（スプライン）の設定] */
spline_count = 17;      
spline_depth = 2;     

$fn = 100;

module delica_armrest_cap() {
    // 1. ドーム状の蓋（ブラッシュクリップ風）
    // 球体を平たく潰して作成
    difference() {
        scale([1, 1, cap_height / (cap_diameter / 2)])
            sphere(d = cap_diameter);
        // 下半分をカットして平らにする
        translate([0, 0, -cap_diameter/2])
            cube([cap_diameter + 1, cap_diameter + 1, cap_diameter], center = true);
    }
    
    // 2. 差し込み軸
    translate([0, 0, -plug_length])
    difference() {
        // メインシャフト
        cylinder(h = plug_length, d = hole_diameter);
        union() {    
            // 歯車状の突起（スプライン）
            for(i = [0 : spline_count - 1]) {
                rotate([0, 0, i * (321 / spline_count+1)])
                translate([(hole_diameter) / 2 , 0, 0])
                cylinder(h = plug_length - groove_offset - groove_width, d = spline_depth, $fn=10);
            }
        }

        // 差し込み口の面取り
        difference(){
        cylinder(h = 6,  d = hole_diameter + 5);
        cylinder(h = 6,  d1 = hole_diameter - 4, d2 = hole_diameter);
        }
        
        // 3. 固定ピン用の溝
        // 溝の位置 = 軸の底から見て (plug_length - groove_offset)
        translate([0, 0, plug_length - groove_offset - groove_width])
        difference() {
            cylinder(h = groove_width, d = hole_diameter+5);
            cylinder(h = groove_width, d =groove_inner_dia);
        }
       
        
        // 中空にして弾性を持たせる（肉抜き）
        translate([0, 0, -1])
            cylinder(h = plug_length - 1, d = groove_inner_dia - 3);
    }
}

// 向きを調整（3Dプリント時はキャップを底にすると綺麗ですが、
// サポートが必要な場合はこのまま出力してください）
delica_armrest_cap();