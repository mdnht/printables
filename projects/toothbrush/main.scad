// 電動歯ブラシ ブラシホルダー
// 首の太さ: 約8mm想定

/* [基本設定] */
// ブラシの本数
num_slots = 3;          // [1:1:10]
// 歯間ブラシ/糸ようじ用の穴の数 (0 ～ ブラシの本数+1 まで)
num_floss_holes = 2;    // [0:1:11]

// 歯ブラシ用の穴の直径 (mm)
neck_dia = 7.0;         // [5.0:0.1:15.0]
// 糸ようじ/歯間ブラシ用の穴の直径 (mm)
floss_hole_dia = 5.0;   // [3.0:0.1:10.0]

/* [詳細寸法] */
/* [Hidden] */
// 出し入れするスリットの幅は穴径より少しだけ狭くして引っかかりをもたせる
slot_width = neck_dia - 0.5;

// ブラシ間のスペース (mm)
slot_spacing = 30;      // [20:1:50]

// 円の滑らかさ
$fn = 60; 

// --- パラメータ ---

holder_thickness = 3.0; // ブラシを支える水平部分（ホルダー部）の厚み
holder_depth = 25.0;    // 前へ突き出す奥行き (mm)
body_length = (num_slots + 1) * slot_spacing; // 全体の横幅 (120mm)

back_thickness = 3.0;   // 背面板全体の厚み（マグネットのザグリ分も含むため少し厚く）
back_height = 30.0;     // マグネットを貼る背面板の高さ (接着面積を稼ぐため大きめに設定)

/* [磁石の設定] */
// マグネットシートの厚み (ザグリの深さ。お使いのシートに合わせて変更してください)
magnet_thickness = 0.5;

/* [Hidden] */
magnet_margin = 5.0;    // ザグリ周囲のフチの太さ

fillet_r = 5.0;         // 全体の角を丸める半径

// 角を丸めた板を作るためのヘルパーモジュール (XY平面: ホルダー用、奥の角は四角のまま丸めない)
module holder_shape(size, r, center = false) {
    x = size[0]; y = size[1]; z = size[2];
    translate(center ? [-x/2, -y/2, -z/2] : [0,0,0])
        union() {
            // 奥側
            translate([0, 0, 0]) cube([x, y-r, z]);
            // 手前側の丸み
            hull() {
                translate([r, y-r, 0]) cylinder(h=z, r=r);
                translate([x-r, y-r, 0]) cylinder(h=z, r=r);
            }
        }
}

// 背面板用：角を丸めた板を作るヘルパーモジュール (XZ平面、上側の角は四角のまま丸めない)
module backplate_shape(size, r, center = false) {
    x = size[0]; y = size[1]; z = size[2];
    translate(center ? [-x/2, -y/2, -z/2] : [0,0,0])
        union() {
            // 上側
            translate([0, 0, r]) cube([x, y, z-r]);
            // 下側の丸み
            hull() {
                translate([r, 0, r]) rotate([-90, 0, 0]) cylinder(h=y, r=r);
                translate([x-r, 0, r]) rotate([-90, 0, 0]) cylinder(h=y, r=r);
            }
        }
}

// L字内側の接合部を滑らかにつなぐためのフィレット
module L_fillet(length, r) {
    difference() {
        translate([0, r/2, -r/2]) cube([length, r, r], center=true);
        translate([0, r, -r]) rotate([0, 90, 0]) cylinder(h=length+0.1, r=r, center=true);
    }
}

// 穴の上下エッジを面取り（面取り量C=1.0、45度）するためのモジュール
module chamfered_hole(dia, h, chamfer = 1.0) {
    // 直線の貫通穴
    translate([0, 0, -1]) cylinder(h = h + 2, d = dia);
    // 上部の面取り (Z=h付近)
    translate([0, 0, h - chamfer]) cylinder(h = chamfer + 1, d1 = dia, d2 = dia + 2 * (chamfer + 1));
    // 下部の面取り (Z=0付近)
    translate([0, 0, -1]) cylinder(h = chamfer + 1, d1 = dia + 2 * (chamfer + 1), d2 = dia);
}

module toothbrush_holder() {
    difference() {
        // 壁にくっつける背面板と、突き出るホルダー部を結合したL字型のベース
        union() {
            // 1. スリットが開く水平なホルダー部分
            translate([0, back_thickness + holder_depth / 2, holder_thickness / 2])
                holder_shape([body_length, holder_depth, holder_thickness], r=fillet_r, center = true);
            
            // 2. マグネットを貼り付ける垂直な背面板
            translate([0, back_thickness / 2, holder_thickness - back_height / 2])
                backplate_shape([body_length, back_thickness, back_height], r=fillet_r, center = true);
                
            // 3. 接合部の内側を滑らかにつなぐフィレット
            translate([0, back_thickness, 0])
                L_fillet(body_length, fillet_r);
        }
        
        // 4. マグネットシートを埋め込むための背面のザグリ（凹み）
        // Y=0側（壁に接する面）から凹ませる
        translate([0, magnet_thickness / 2 - 0.1, holder_thickness - back_height / 2])
            backplate_shape([body_length - magnet_margin * 2, magnet_thickness + 0.2, back_height - magnet_margin * 2], r=max(fillet_r - magnet_margin, 0.1), center = true);
        
        // ブラシを掛ける3つのスロットをくり抜く
        for (i = [0 : num_slots - 1]) {
            x_pos = -body_length / 2 + slot_spacing + (i * slot_spacing);
            
            // 丸穴: 首かけ用の面取り穴
            translate([x_pos, back_thickness + holder_depth * 0.4, 0])
                chamfered_hole(dia = neck_dia, h = holder_thickness, chamfer = 1.0);
            
            // スリット: 丸穴から前方（手前側）に真っ直ぐ抜ける開口部
            translate([x_pos, back_thickness + holder_depth * 0.4 + holder_depth / 2, holder_thickness / 2])
                cube([slot_width, holder_depth, holder_thickness + 2], center = true);
                
            // スリット入り口の面取り (Z方向両端も軽く面取りする場合はスリット側のみ少し面倒ですが、ここは角Rのみにする)
            // (既存のスリット入り口のR5は維持)
            translate([x_pos - slot_width / 2 - fillet_r, back_thickness + holder_depth - fillet_r, -1])
                difference() {
                    cube([fillet_r + 0.1, fillet_r + 0.1, holder_thickness + 2]);
                    translate([0, 0, -1]) cylinder(h = holder_thickness + 4, r = fillet_r);
                }
            translate([x_pos + slot_width / 2 - 0.1, back_thickness + holder_depth - fillet_r, -1])
                difference() {
                    cube([fillet_r + 0.1, fillet_r + 0.1, holder_thickness + 2]);
                    translate([fillet_r + 0.1, 0, -1]) cylinder(h = holder_thickness + 4, r = fillet_r);
                }
        }
        
        // 5. 空きスペース（両端およびホルダー間）に糸ようじ・歯間ブラシ用の穴を配置
        // 穴は最大 (num_slots + 1) 個まで配置可能
        if (num_floss_holes > 0) {
            actual_holes = min(num_floss_holes, num_slots + 1);
            for (k = [0 : actual_holes - 1]) {
                // 1個目は左端（プレート端と、左端の歯ブラシ穴の端の中間）
                // 2個目は右端（プレート端と、右端の歯ブラシ穴の端の中間）
                // 3個目以降はホルダー間（歯ブラシ穴と歯ブラシ穴のちょうど中間）
                x_pos = (k == 0) ? -body_length / 2 + slot_spacing / 2 - neck_dia / 4 :
                        (k == 1) ?  body_length / 2 - slot_spacing / 2 + neck_dia / 4 :
                        -body_length / 2 + slot_spacing * 1.5 + (k - 2) * slot_spacing;
                
                // ブラシの柄と干渉しないよう、少し手前（Y方向）に配置する
                translate([x_pos, back_thickness + holder_depth * 0.65, 0])
                    chamfered_hole(dia = floss_hole_dia, h = holder_thickness, chamfer = 1.0);
            }
        }
    }
}

// 描画実行
// 本体の描画（一体化済み）
color("WhiteSmoke") toothbrush_holder();

