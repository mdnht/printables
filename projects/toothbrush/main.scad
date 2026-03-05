// 電動歯ブラシ ブラシホルダー (3本用)
// 首の太さ: 約8mm想定

$fn = 60; // 円の滑らかさ

// --- パラメータ ---
neck_dia = 9.0;         // 首かけ部分の穴の直径 (8mmの首に対して少し余裕を持たせる)
slot_width = 8.5;       // 出し入れするスリットの幅 (少し引っかかりつつ入る絶妙な幅)
num_slots = 3;          // ブラシの本数
slot_spacing = 30;      // ブラシ間のスペース (mm)

floss_hole_dia = 5.0;   // 両端に開ける糸ようじ用の穴の直径

brush_insert_od = 15.0; // 歯ブラシ用インサートの外径
floss_insert_od = 11.0; // 糸ようじ用インサートの外径 (穴5.0mm + 縁の幅3.0mm*2)
insert_clearance = 0.2; // リングをはめ込むためのクリアランス

holder_thickness = 5.0; // ブラシを支える水平部分（ホルダー部）の厚み
holder_depth = 25.0;    // 前へ突き出す奥行き (mm)
body_length = (num_slots + 1) * slot_spacing; // 全体の横幅 (120mm)

back_thickness = 4.0;   // 背面板全体の厚み（マグネットのザグリ分も含むため少し厚く）
back_height = 30.0;     // マグネットを貼る背面板の高さ (接着面積を稼ぐため大きめに設定)
magnet_thickness = 1.0; // マグネットシートの厚み (ザグリの深さ。お使いのシートに合わせて変更してください)
magnet_margin = 2.0;    // ザグリ周囲のフチの太さ

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
            
            // 丸穴: インサートリングをはめこむための大きな穴をくり抜く
            translate([x_pos, back_thickness + holder_depth * 0.4, -1])
                cylinder(h = holder_thickness + 2, d = brush_insert_od + insert_clearance * 2);
            
            // スリット: 丸穴から前方（手前側）に真っ直ぐ抜ける開口部 (インサートのスリットより少しだけ広くする)
            translate([x_pos, back_thickness + holder_depth * 0.4 + holder_depth / 2, holder_thickness / 2])
                cube([slot_width + insert_clearance * 2, holder_depth, holder_thickness + 2], center = true);
                
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
        
        // 5. 両端の空きスペースに糸ようじ用の穴を配置
        // 糸ようじ用も色分けインサートにするため、大きめの穴をくり抜く
        for (x_pos = [-body_length / 2 + 10, body_length / 2 - 10]) {
            translate([x_pos, back_thickness + holder_depth * 0.4, -1])
                cylinder(h = holder_thickness + 2, d = floss_insert_od + insert_clearance * 2);
        }
    }
}

// 色分け用のインサートリング（歯ブラシ用）
module brush_color_insert() {
    difference() {
        // 外形
        cylinder(h = holder_thickness, d = brush_insert_od);
        
        // 首かけ用の面取り穴
        chamfered_hole(dia = neck_dia, h = holder_thickness, chamfer = 1.0);
        
        // 前方のスリット
        translate([0, holder_depth / 2, holder_thickness / 2])
            cube([slot_width, holder_depth, holder_thickness + 2], center = true);
    }
}

// 色分け用のインサートリング（糸ようじ用）
module floss_color_insert() {
    difference() {
        // 外形
        cylinder(h = holder_thickness, d = floss_insert_od);
        
        // 糸ようじ用の面取り穴
        chamfered_hole(dia = floss_hole_dia, h = holder_thickness, chamfer = 1.0);
    }
}

// 部品のレイアウト配置
module assembly() {
    // 本体
    color("WhiteSmoke") toothbrush_holder();
    
    // 歯ブラシ用インサートリングを所定の位置にはめ込んだ状態に配置
    for (i = [0 : num_slots - 1]) {
        x_pos = -body_length / 2 + slot_spacing + (i * slot_spacing);
        // 視覚的に区別しやすいよう色を分けて配置
        c = (i == 0) ? "Tomato" : ((i == 1) ? "MediumSeaGreen" : "DodgerBlue");
        color(c) translate([x_pos, back_thickness + holder_depth * 0.4, 0])
            brush_color_insert();
    }
    
    // 糸ようじ用インサートリングを所定の位置にはめ込んだ状態に配置
    color("Gold") translate([-body_length / 2 + 10, back_thickness + holder_depth * 0.4, 0])
        floss_color_insert();
    color("Orange") translate([body_length / 2 - 10, back_thickness + holder_depth * 0.4, 0])
        floss_color_insert();
}

// 描画実行
// 本体の所定の位置にインサートをはめ込んだ状態で出力（プレビュー用）
// ※実際に3Dプリントする際は、本体とインサートを分けて出力してください。
assembly();
