// スピーカースタンド (Anker SoundCore Motion B用)
include <../../libs/BOSL2/std.scad>

// スピーカーの寸法 (Anker SoundCore Motion B: 約171 x 56 x 48)
speaker_width = 171.0;
speaker_depth = 48.0;
speaker_corner_r = 3.0; // 角の丸み
wall_thick = 2.0;       // 最低限の壁厚
corner_support_size = 15; // 四角を支える爪の一辺の長さ
corner_support_height = 10; // 爪の高さ

// デスクマウント部 (縦35mm x 奥行き18.5mmの角材にスライド)
desk_bar_height = 35.0; // 縦方向
desk_bar_depth = 18.5;  // 奥行き方向
mount_thick = 3.0; // マウント部壁厚
mount_length = 40.0; // スライド方向(幅)の長さ

// 15度単位の回転ジョイント (360 / 15 = 24)
joint_teeth = 24;
joint_radius = 10.0; // マウント部の角の丸め(R2)を考慮し、平坦部(20.5mm)に収まるように半径を10.0mm(直径20mm)に縮小
joint_height = 3; // ギア部分の高さ（3mm）
joint_base_h = 5.0; // ジョイント根本のギアなし円柱部分の高さ
clearance = 0.2; // 調整用クリアランス

// スタンド本体の基本の厚み (ジョイント穴が開かないようにしっかり厚みを持たせる)
base_thick = 10.0; 

// スタンド本体中央の厚みを確保（ジョイントの凹み用）
base_center_thick = max(base_thick, joint_height + 2.0);

// 星形（ギア状）の深い切り込みを持つジョイント形状を生成するモジュール
module joint_shape(r, h, clr=0) {
    // ギアの切り込み深さを 1.0mm に浅くする
    core_radius = r - 1.0; 
    
    // 各歯のピッチ角度 (360 / 24 = 15度)
    P_angle = 360 / joint_teeth; 
    
    // 山の頂点（外側）は少し平ら（平坦）な部分を残し、谷（凹み）は鋭い三角形になるようにする
    top_flat_angle = 3.5; // 少し浅くなった分、山の平らな部分の角度幅をわずかに広げる (3.5度)
    
    linear_extrude(height=h) {
        offset(delta = -clr) {
            polygon(points=[
                for(i = [0 : joint_teeth - 1])
                let(
                    theta = i * P_angle,
                    theta_next_valley = theta + (P_angle / 2), // 次の谷の中心角度
                    t_half = top_flat_angle / 2
                )
                for(pt = [
                    [ r * cos(theta - t_half), r * sin(theta - t_half) ], // 山の平らな部分の開始点
                    [ r * cos(theta + t_half), r * sin(theta + t_half) ], // 山の平らな部分の終了点
                    [ core_radius * cos(theta_next_valley), core_radius * sin(theta_next_valley) ] // 谷の底（1点）
                ]) pt
            ]);
        }
    }
}

// スピーカーベースプレート（上部）
module speaker_base_plate() {
    center_r = joint_radius + 4.0; // 中央の円柱の半径
    corner_r = 8.0; // 四隅の円柱の半径（スピーカーをしっかりホールドできるよう少し太く戻す）
    
    // 高さを個別に制御
    center_h = joint_height + joint_base_h + 3.0; // ジョイントが刺さるため、必要な厚みを確保 (ギア分 + 円柱延長分 + 底厚み)
    beam_h = 6.0; // 縦の曲げに強くするため高さを出す（板状）
    beam_w = 3.0; // 梁の厚みは薄くする
    
    // コーナーの円柱の配置位置（スピーカーの角の丸みに同心に合わせる）
    xc = (speaker_width/2) - speaker_corner_r; 
    yc = (speaker_depth/2) - speaker_corner_r;

    difference() {
        union() {
            // 中央の円柱 (ジョイント受け用)
            cylinder(r=center_r, h=center_h, anchor=BOTTOM);
            
            // 四隅の円柱と、中央をつなぐ梁 (X型・薄い)
            for(x = [xc, -xc]) {
                for(y = [yc, -yc]) {
                    // 四隅の支え円柱 (下側に伸ばし、底面を中央の円柱と同じZ=0に揃える)
                    translate([x, y, 0]) {
                        cylinder(r=corner_r, h=center_h + corner_support_height, anchor=BOTTOM);
                    }
                    
                    // 中央から四隅の爪の中心へのストレートな梁 (底面 Z=0 に合わせる)
                    hull() {
                        cylinder(r=beam_w/2, h=beam_h, anchor=BOTTOM);
                        translate([x, y, 0]) {
                            cylinder(r=beam_w/2, h=beam_h, anchor=BOTTOM);
                        }
                    }
                }
            }
        }
        
        // 四隅の支えだけ残し、スピーカーが収まるメイン空間をくり抜く
        // スピーカーは「center_h(6mm)」の高さに乗るため、center_h以上の空間をくり抜く
        translate([0, 0, center_h]) {
            cuboid([speaker_width, speaker_depth, corner_support_height+1], rounding=speaker_corner_r, edges="Z", anchor=BOTTOM);
        }
        
        // 回転ジョイント（メス：スタンド側）
        // 底面(Z=0)から直接上に向かって彫る
        translate([0, 0, -0.1]) {
            // まずギアなしの円柱の穴を開ける（5mm深さ＋クリアランス余白）
            cylinder(r=joint_radius + clearance, h=joint_base_h + 0.1, anchor=BOTTOM);
            // その奥にオス側が刺さるための星形（ギア状）の穴を開ける
            translate([0, 0, joint_base_h]) {
                joint_shape(joint_radius, joint_height + 0.2, 0); // メス側（穴）は基準サイズ
            }
        }
    }
}

// デスクマウント（下部）
module desk_mount() {
    union() {
        difference() {
            // マウント部外形 (X: スライド方向, Y: 奥行き, Z: 縦)
            cuboid([mount_length, desk_bar_depth + mount_thick*2, desk_bar_height + mount_thick*2], anchor=BOTTOM, rounding=2);
            
            // デスク角材の貫通穴 (X方向にスライドイン)
            translate([0, 0, mount_thick]) {
                cuboid([mount_length+1, desk_bar_depth, desk_bar_height], anchor=BOTTOM);
            }
            
            // スライドインできるように底面側などを開く（コの字型にするなら以下を追加）
            /*
            translate([0, (desk_bar_depth/2) + mount_thick, mount_thick + (desk_bar_height/2)]) {
                cuboid([mount_length+1, mount_thick*2, desk_bar_height], anchor=CENTER);
            }
            */
        }
        
        // 回転ジョイント（オス）
        translate([0, 0, desk_bar_height + mount_thick*2]) {
            // 根本のギアなしの円柱部分 (5mm)
            cylinder(r=joint_radius - clearance, h=joint_base_h, anchor=BOTTOM);
            
            // その上にギア部分を乗せる
            translate([0, 0, joint_base_h]) {
                // difference で直接角のエッジを削り取る方法に変更（確実に透けないようにする）
                difference() {
                    // オス側のギア形状 (高さは交差で切るので少し長めに出しておく)
                    joint_shape(joint_radius, joint_height, clearance);
                    
                    // オス側の先端の角（ふち）を削り取って面取りするためのドーナツ状のくさび
                    // Z軸の一番上に配置し、外側から内側斜めに向かって削る
                    translate([0, 0, joint_height - 1.0]) {
                        difference() {
                            // 削り取る範囲（ジョイントより一回り大きい円柱）
                            cylinder(r=joint_radius + 2, h=1.0 + 0.1, anchor=BOTTOM);
                            // 残す部分（下に向かって広がる円錐台）
                            // r1(下)は削らないように大きく、r2(上)に向かって小さくしていく
                            cylinder(r1=joint_radius + 0.5, r2=joint_radius - 1.0, h=1.0 + 0.1, anchor=BOTTOM);
                        }
                    }
                }
            }
        }
    }
}

// 組み立て（プレビュー用）
module assembly() {
    color("lightblue") {
        // 接合部の構造が見えるように上方に隙間を空けてプレビューします (+ 30)
        translate([0, 0, desk_bar_height + mount_thick*2 + joint_base_h + joint_height + 30]) {
            speaker_base_plate();
        }
    }
    color("darkgray") {
        desk_mount();
    }
}

// パーツ別出力 (いずれかのコメントを外して個別にSTL出力する)

assembly();
// speaker_base_plate();
// desk_mount();
