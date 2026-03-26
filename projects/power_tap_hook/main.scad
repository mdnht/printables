/* 
    電源タップ用フック (Power Tap Hook)
    直径20mmの丸パイプに、電源タップ（W32 x H26）を引っ掛けてぶら下げるためのパーツ。
    
    パイプ径: 20mm
    電源タップ: 32mm x 26mmを変形（コンセントを横から差すため、26mm x 32mmの縦置きレイアウトでモデリング）
    （本パーツを2つほどプリントし、タップをスライドさせて通すことで安定して保持可能です。左右どちら向きにも挿入できます）
*/

// --- 設定 ---
$fn = 100;

// --- パラメータ ---
pipe_dia = 20;   // パイプ径
// コンセントを上面ではなく横方向から差せるようにするため、幅と高さを入れ替えて縦置き保持にします
tap_w = 26;      // 電源タップの幅 (元H)
tap_h = 32;      // 電源タップの高さ (元W)

wall_thickness = 4.5; // 壁の厚み（強度確保のため厚めの4.5mm）
extrusion_width = 15; // フック自体の幅（押し出し量）

clearance_pipe = 0.5; // パイプがスナップフィットするためのクリアランス
clearance_tap = 1.0;  // タップがスムーズに通るためのクリアランス

drop_distance = 15;   // パイプとタップホルダーの間の距離（大きなACアダプタ類がパイプと干渉しないよう余裕を持たせました）

// --- 計算値 ---
pr = pipe_dia/2 + clearance_pipe/2; // パイプ内径 (約10.25)
PR = pr + wall_thickness;           // パイプ外径 (約14.75)

tw = tap_w + clearance_tap;         // タップホルダーの内側幅 (33)
th = tap_h + clearance_tap;         // タップホルダーの内側高さ (27)

// 角を丸めた四角形を生成するヘルパーモジュール
module rounded_square(size, r=2) {
    translate([r, r])
        offset(r=r)
            square([size[0] - 2*r, size[1] - 2*r]);
}

// --- メインモジュール ---
module power_tap_hook() {
    linear_extrude(height = extrusion_width, convexity=4) {
        difference() {
            // 1. ベースとなる基本形状
            union() {
                // パイプフック外形
                circle(r = PR);
                
                // 左側のアーム（パイプとタップホルダーを接続）
                // hull関数を用いて美しい滑らかな接続を作成
                hull() {
                    // パイプ側アンカー
                    translate([-PR + wall_thickness/2, 0])
                        circle(r = wall_thickness/2);
                        
                    // タップホルダー側アンカー (左上角のR2丸みにぴったり合わせる)
                    translate([-(tw/2 + wall_thickness) + 2, -PR - drop_distance - 2])
                        circle(r = 2);
                }
                
                // タップホルダー外形 (角を丸めて手触りと見た目を向上)
                translate([-(tw/2 + wall_thickness), -PR - drop_distance - th - 2*wall_thickness])
                    rounded_square([tw + 2*wall_thickness, th + 2*wall_thickness], r=2);
            }
            
            // 2. くり抜き処理
            
            // パイプを通す穴
            circle(r = pr);
            
            // 電源タップを通すホルダー穴（左側内角は丸めて応力集中を防ぐ）
            translate([-tw/2, -PR - drop_distance - th - wall_thickness])
                rounded_square([tw, th], r=1.5);
                
            // ★ツメ（返し）部分のホールド力を最大限確保するため、右半分の内角は丸めずに直角にくり抜く
            translate([0, -PR - drop_distance - th - wall_thickness])
                square([tw/2, th]);
                
            // ★右側開放部にスナップフィット用の「返し（フック）」を形成する
            // 外側は広いスロープになっており、タップを押し込むとアームが開きます
            // タップが入った後は上下2mmの「返し」が引っかかり抜け止めとしてしっかりホールドします
            translate([tw/2, -PR - drop_distance - th - wall_thickness])
                polygon([
                    [0, 2],                                        // 右下フックの「返し」高さ（内側へ2mm残す）
                    [wall_thickness + 2, -wall_thickness + 1],     // 下ガイドスロープ（外側はタップより広く開く）
                    [wall_thickness + 2, th + wall_thickness - 1], // 上ガイドスロープ（外側はタップより広く開く）
                    [0, th - 2]                                    // 右上フックの「返し」高さ（内側へ2mm残す）
                ]);
                
            // パイプへスナップ固定するための下部開口
            // X=-6で左側のツメ、Y=-6で右側のツメを形成。約14.6mmの開口により、20mmパイプへ「パチン」とはめ込み可能。
            translate([-6, -PR - 5])
                square([PR + 15, PR + 5 - 6]);
                
            // 右側のツメ先端への面取り加工 (挿入時のガイドとなるスロープ)
            polygon([
                [pr*0.9, -6],   // X=8.3から少し余裕を持たせ、約1mmの平らなツメを残す
                [PR + 2, -6],
                [PR + 2, -1]    // 挿入時にパイプが滑りやすくするスロープ
            ]);
        }
    }
}

// レンダリング実行
power_tap_hook();
