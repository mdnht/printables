/*
================================================================================
浜名湖遊覧船風・お風呂ボートトイ (Lake Hamana Catamaran Bath Toy)
================================================================================
本モデルは、浜名湖のカタマラン（双胴型）遊覧船をモチーフにした8cmミニチュアトイです。
左右に分かれた2つの船体（双胴ハル）と、中央を貫く美しい船首アーチが特徴です。

★ ギミックはすべて健在＆パワーアップ！
1. 操舵輪（ハンドル） - カタマランの広いダッシュボードで回転します
2. 船室ドア - プリントインプレイス(PIP)で組み立て不要！印刷した瞬間からパタパタ動きます
3. 引き出し - 船体がカタマランになり幅広く長くなり、収納力がUPしました！

■ 浜名湖遊覧船を再現したプレミアム・ディテール
- 二層構造のデッキと、2階（屋根上）のアッパーデッキ手すり（フェンス）
- 客船らしい3連パノラマ四角窓と白い窓枠
- 屋根の上に立つ、安全でリアルなゴールドキャップ付きマスト（煙突）
- 船体カラーを実物同様の「アイボリー, ワインレッド, ホワイト, ゴールド」で再現

■ 3Dプリント推奨・完全サポートフリー(DFAM)設定
- 素材: PETG（推奨）または PLA
- 積層ピッチ: 0.15mm 〜 0.20mm
- インフィル: 10% 〜 15% (浮力が最大になり、水密小部屋ができて絶対に沈みません)
- 外壁（Wall/Perimeter）: 3 〜 4周 (水の染み込みを完全に防ぎます)
- サポート: 完全不要！ (窓のインセット化、ひさしとメインデッキ裏の45度テーパー化により、サポート材ゼロで驚くほど綺麗に印刷できます！)
================================================================================
*/

/* [General Settings] */
// 表示またはレンダリングするパーツを選択
part = "assembly"; // [assembly:組み立て・アニメーション表示, hull:船体(Hull), steering:ハンドル(Steering Wheel), door:ドア(Door), drawer:引き出し(Drawer)]

// 3Dモデルの滑らかさ
$fn = 60; // [30:低, 60:中, 100:高]

/* [Animation Settings] */
// アニメーションを手動でテストするための角度/位置
manual_steering_angle = 0; // [-180:180]
manual_door_angle = 0;     // [0:120]
manual_drawer_slide = 0;   // [0:12]

// --- アニメーション・パラメータの自動計算 ---
t_cycle = $t;
steering_rot = ($t > 0) ? $t * 360 * 3 : manual_steering_angle;
door_angle   = ($t > 0) ? (sin($t * 360 - 90) + 1) * 55 : manual_door_angle; 
drawer_pos   = ($t > 0) ? (sin($t * 360 - 90) + 1) * 7.5 : manual_drawer_slide; // 最大15mmスライド

// =============================================================================
// メイン処理 (Main Controller)
// =============================================================================

if (part == "assembly") {
    // 組み立てアニメーション表示 (浜名湖遊覧船カラーで美しく色分け)
    render() {
        // 1. 双胴船体 (Catamaran Hull) - 実船同様の気品あるアイボリー
        color("Ivory") 
            boat_hull();
        
        // 2. ハンドル (Steering Wheel) - ゴールド
        // キャビン前面ダッシュボード (x = 7.2, y = 0, z = 20.5)
        // 壁(x=7)からわずかに(0.2mm)浮かせ、高さを20.5にしてめり込みを完全に排除します
        translate([7.2, 0, 20.5])
            rotate([0, -90, 0])
                translate([0, 0, -3]) // ボス厚みオフセット
                    rotate([0, 0, steering_rot])
                        color("Gold") 
                            steering_wheel();
                            
        // 3. ドア (Door) - ゴールド of 華やかな客室ドア
        // 左舷ヒンジ軸 (x = 0, y = 11.5, z = 12.5) 
        translate([0, 11.5, 12.5])
            rotate([0, 0, door_angle])
                color("Gold") 
                    cabin_door();
                    
        // 4. 引き出し (Drawer) - 船体中央後ろから引き出せるゴールドの船尾収納
        // キャビン後端 (x = -27) から差し込み
        translate([-27 - drawer_pos, 0, 14.3])
            color("Gold") 
                drawer();
    }

} else if (part == "hull") {
    // 船体単体 (3Dプリント時の向き：底面がビルドプレートに接する、サポート不要)
    boat_hull();
    
} else if (part == "steering") {
    // ハンドル単体
    steering_wheel();
    
} else if (part == "door") {
    // ドア単体 (自動的に寝かせた状態で出力されます)
    rotate([90, 0, 0])
        cabin_door();
        
} else if (part == "drawer") {
    // 引き出し単体
    drawer();
}

// =============================================================================
// 各パーツのモジュール定義 (Module Definitions)
// =============================================================================

// -----------------------------------------------------------------------------
// 1. 船体モジュール (Catamaran Boat Hull)
// -----------------------------------------------------------------------------
module boat_hull() {
    difference() {
        union() {
            // カタマラン（双胴船）メインのソリッド形状
            boat_hull_solid();
            
            // ワイドキャビン（船室 - 実船のようなワインレッドカラー、ひさしをDFAM化）
            translate([-10, 0, 12.5])
                color("FireBrick") cabin_outer();
                
            // 2階アッパーデッキの手すり（ホワイト）
            translate([-10, 0, 30.5])
                color("White") roof_railing();
                
            // 安全でリアルなゴールドキャップ付きマスト（煙突）
            translate([-17, 0, 30.5])
                color("DarkSlateGray") tourist_ship_mast();
                
            // 船首フロントデッキの手すり（ホワイト）
            translate([0, 0, 12.5])
                color("White") front_railing();

            // キャビンの右舷窓枠（インセット窓にピッタリと重なる、白い窓枠）
            translate([-14, -11.6, 21.5]) 
                rotate([90, 0, 0]) 
                    color("White") cabin_window_frame();
            translate([-6, -11.6, 21.5]) 
                rotate([90, 0, 0]) 
                    color("White") cabin_window_frame();
            translate([2, -11.6, 21.5]) 
                rotate([90, 0, 0]) 
                    color("White") cabin_window_frame();
                    
            // コックピット内のシート（ベンチ）
            cockpit_seat();
        }
        
        // --- くり抜き・穴開け加工 ---
        
        // B. キャビン内の引き出しスロットのくり抜き (カタマラン化で奥行きを23mmに拡張)
        translate([-29, 0, 12.5 + 1.5]) 
            drawer_slot_cutout();
            
        // C. キャビン左舷側のドア開口部のくり抜き
        translate([0, 0, 12.5])
            door_opening_cutout();
            
        // D. ドアヒンジ用のプリントインプレイス用ピボットソケット穴 (クリアランス0.35mmを確保)
        // 下ピボット受け穴 (z=12.5基準で、デッキ内の z=-1.8〜0.3 の範囲を削る)
        translate([0, 11.5, 12.5 - 1.8])
            cylinder(d=3.9, h=2.1); // ピン直径3.2mm + 両側クリアランス0.35mm = 3.9mm
            
        // 上ピボット受け穴 (z=12.5基準で、キャビン天井内の z=14.5〜16.6 の範囲を削る、手すりは一切貫通しない！)
        translate([0, 11.5, 12.5 + 14.5])
            cylinder(d=3.9, h=2.1);
            
        // E. ハンドル差し込み用の穴 (直径4.4mm)
        translate([7, 0, 20.5])
            rotate([0, 90, 0])
                cylinder(d=4.4, h=10, center=true);
                
        // F. 右舷側の客室用パノラマ窓のインセットディテール (深さ1.2mmでサポート完全に不要＆水密性抜群！)
        for (x = [-14, -6, 2]) {
            translate([x, -11.2, 21.5]) // 外壁の面 y = -11.0 から 1.2mm だけ窪ませる
                rotate([90, 0, 0])
                    hull() {
                        translate([-2.5, -3, 0]) cylinder(r=1, h=1.5);
                        translate([ 2.5, -3, 0]) cylinder(r=1, h=1.5);
                        translate([-2.5,  3, 0]) cylinder(r=1, h=1.5);
                        translate([ 2.5,  3, 0]) cylinder(r=1, h=1.5);
                    }
        }
                
        // G. 水抜き穴 (カタマランの左右ハル底にそれぞれ開けて完璧に水抜き、コックピット床やベンチは一切傷つけない！)
        // 左舷ハル
        translate([15, 10.5, -2]) cylinder(d=3.5, h=13.5);
        translate([-10, 10.5, -2]) cylinder(d=3.5, h=13.5);
        // 右舷ハル
        translate([15, -10.5, -2]) cylinder(d=3.5, h=13.5);
        translate([-10, -10.5, -2]) cylinder(d=3.5, h=13.5);
    }
}

// 双胴船（カタマラン）メインソリッド形状
module boat_hull_solid() {
    difference() {
        // 2つのハルとブリッジデッキを合成
        union() {
            // 左舷ハル
            translate([0, 10.5, 0])
                single_hull();
            // 右舷ハル
            translate([0, -10.5, 0])
                scale([1, -1, 1]) 
                    single_hull();
                    
            // センターブリッジ（2つの船体を繋ぐ中央土台）
            hull() {
                translate([-42, -12, 7]) cube([60, 24, 4.5]);
                translate([18, -8, 7]) cube([5, 16, 4.5]);
            }
            
            // メインデッキ（DFAM傾斜デッキ - 下部を45度の傾斜にすることで、張り出し部分のサポートを100%不要に！）
            hull() {
                // デッキ天面 (フル幅で平らな広域甲板、z=11.5〜12.5)
                translate([-45, -15.5, 11.5]) cube([75, 31, 1.0]);
                translate([30, -10, 11.5]) cube([2, 20, 1.0]);
                
                // サポートフリー斜めベベルベース (z=9.5の位置でストラット幅と一体化する狭めのベース)
                translate([-42, -11, 9.5]) cube([69, 22, 0.1]);
                translate([20, -7, 9.5]) cube([2, 14, 0.1]);
            }
        }
    }
}

// 1本のハルのなだらかな流線型 (左右のハル自体が、平らな船尾を持つ立派な「ミニボート」になっているデザイン)
module single_hull() {
    // 1. 下部の均一な太さのボート型ハル (幅12.0mm, 高さ7.5mmで一定、前後両端を優しく丸めた安全設計)
    difference() {
        hull() {
            // 船首の尖ったノーズ先 (なだらかに絞り込み、ユーザーのスケッチの流線型船首を美しく再現、x=34)
            translate([34, 0, 3.75]) scale([1, 1, 0.625]) sphere(d=4.0);
            
            // 均一胴体の前側起点 (x=22) - ここから後ろは完璧にまっすぐな12mm幅
            translate([22, 0, 3.75]) scale([1, 1, 0.625]) sphere(d=12.0);
            
            // 後端 (丸み) - デッキ後端に合わせて x=-35 までしっかりと後ろへ延長
            translate([-35, 0, 3.75]) scale([1, 1, 0.625]) sphere(d=12.0);
        }
        // 底面フラットカット (z=0 から z=0.6 までを水平スライス)
        translate([0, 0, -5 + 0.6])
            cube([85, 15, 10], center=true); // 延長に合わせて長さを85mmに拡張
            
        // 上面フラットカット (z=6.0 以上を水平スライスしてボートの平らな甲板を表現)
        translate([0, 0, 5 + 6.0])
            cube([85, 15, 10], center=true); // 延長に合わせて長さを85mmに拡張
    }
    
    // 2. 上部のスリムなストラット (柱の前端をx=29までしっかりと伸ばし、カヌー先端と完全に一体化)
    hull() {
        // 前端 (ポンツーン前端近くまでしっかり伸ばす)
        translate([26, 0, 6.0]) cylinder(d=5.0, h=5.5);
        // 後端 - ポンツーンの延長に合わせて x=-33 まで後ろへ延長してしっかり支える
        translate([-33, 0, 6.0]) cylinder(d=5.0, h=5.5);
    }
}

// ワイドキャビン外観 (前後長34mmに拡張し客船らしくスタイリッシュに、かつサポート不要なDFAM設計)
module cabin_outer() {
    // キャビン本体
    hull() {
        translate([-15, -11, 0]) cylinder(r=2, h=18);
        translate([ 15, -11, 0]) cylinder(r=2, h=18);
        translate([-15,  11, 0]) cylinder(r=2, h=18);
        translate([ 15,  11, 0]) cylinder(r=2, h=18);
    }
    
    // 【DFAM】フロントキャビンバイザー（45度のなだらかな傾斜を持たせ、サポート材を100%不要に！）
    // キャビン上部(z=14.0)からひさし上端(z=18.0)に向けて、緩やかにフレア状に広がる形状
    hull() {
        // ひさし上端 (厚み1.5mm部分)
        translate([-16, -12, 16.5]) cylinder(r=1.5, h=1.5);
        translate([ 16.5, -12, 16.5]) cylinder(r=1.5, h=1.5);
        translate([-16,  12, 16.5]) cylinder(r=1.5, h=1.5);
        translate([ 16.5,  12, 16.5]) cylinder(r=1.5, h=1.5);
        
        // 斜めサポート移行用ベース (z=14.0の位置で壁面に接する小さなベース点)
        translate([-15, -11, 14.0]) cylinder(r=2.0, h=0.1);
        translate([ 15.0, -11, 14.0]) cylinder(r=2.0, h=0.1);
        translate([-15,  11, 14.0]) cylinder(r=2.0, h=0.1);
        translate([ 15.0,  11, 14.0]) cylinder(r=2.0, h=0.1);
    }
}

// 2階アッパーデッキの手すり (サポートなしで綺麗にブリッジ印刷できる格子設計)
module roof_railing() {
    difference() {
        // 外枠フェンス
        hull() {
            translate([-14.5, -11, 0]) cylinder(r=1, h=4.5);
            translate([ 14.5, -11, 0]) cylinder(r=1, h=4.5);
            translate([-14.5,  11, 0]) cylinder(r=1, h=4.5);
            translate([ 14.5,  11, 0]) cylinder(r=1, h=4.5);
        }
        // 内側くり抜き
        hull() {
            translate([-13.3, -9.8, -1]) cylinder(r=1, h=7);
            translate([ 13.3, -9.8, -1]) cylinder(r=1, h=7);
            translate([-13.3,  9.8, -1]) cylinder(r=1, h=7);
            translate([ 13.3,  9.8, -1]) cylinder(r=1, h=7);
        }
        
        // 縦方向の格子スリット (幅2mmで印刷しやすいブリッジを構成)
        for (x = [-12:4:12]) {
            translate([x, 0, 1.2])
                cube([2.0, 26, 2.5], center=true);
        }
        for (y = [-8:4:8]) {
            translate([0, y, 1.2])
                cube([32, 2.0, 2.5], center=true);
        }
    }
}

// 引き出しスロットのくり抜き形状 (カタマラン化に伴い奥行きを23mmに拡大)
module drawer_slot_cutout() {
    // 幅16mm, 高さ10mm, 奥行き23mm
    translate([-29, -8, 0])
        cube([24, 16, 10]);
}

// ドア開口部およびヒンジ回転用の逃げ
module door_opening_cutout() {
    // 開口部
    translate([-12, 9.5, 0])
        cube([12, 4, 15.5]);
    
    // ヒンジの回転逃げ
    translate([0, 11.5, 0])
        cylinder(d=5.5, h=15.5);
}

// コックピット内のシート
module cockpit_seat() {
    // 操縦席ベンチ (フラットデッキ面 z=12.5 に合わせて配置)
    translate([12, -10, 16.5])
        color("Peru") cube([4, 20, 1.5]);
    // ベンチの支柱 (デッキ面 z=12.5 からベンチ 16.5 まで綺麗に接地)
    translate([12, -8, 12.5])
        color("Peru") cube([4, 2.5, 4]);
    translate([12, 5.5, 12.5])
        color("Peru") cube([4, 2.5, 4]);
}

// 船首フロントデッキの手すり (高さ4.5mm, 3Dプリント時にサポート不要なブリッジ幅設計)
module front_railing() {
    difference() {
        // 外枠 (船首の絞り形状に沿ってテーパーさせた多角形)
        hull() {
            translate([16, -14.8, 0]) cylinder(r=0.8, h=4.5);
            translate([29, -8.2, 0]) cylinder(r=0.8, h=4.5);
            translate([16,  14.8, 0]) cylinder(r=0.8, h=4.5);
            translate([29,  8.2, 0]) cylinder(r=0.8, h=4.5);
        }
        // 内側をくり抜いて厚み1.2mmにする
        hull() {
            translate([15.5, -13.6, -1]) cylinder(r=0.8, h=7);
            translate([27.5, -7.0, -1]) cylinder(r=0.8, h=7);
            translate([15.5,  13.6, -1]) cylinder(r=0.8, h=7);
            translate([27.5,  7.0, -1]) cylinder(r=0.8, h=7);
        }
        
        // 操縦席コックピット側（後方 x=15.5付近）をくり抜いて開口し、操縦席からの出入り通路を作る
        translate([14, 0, 2])
            cube([4, 28, 6], center=true);
            
        // 手すりのスリット格子 (1.8mm幅で綺麗にブリッジ印刷可能)
        for (x = [18:4:28]) {
            translate([x, 0, 1.2])
                cube([1.8, 32, 2.5], center=true);
        }
    }
}

// 遊覧船の安全な煙突（排気口付き）
module tourist_ship_mast() {
    // メインポール（黒）
    cylinder(d=4.5, h=14);
    // ゴールドのアクセントリング
    translate([0, 0, 10])
        color("Gold") cylinder(d=6, h=2.5);
    // 先端の安全でリアルなゴールド煙突キャップ（排気口の凹み付き）
    translate([0, 0, 14]) {
        color("Gold") difference() {
            // 外殻
            cylinder(d=5, h=3);
            // 煙突の排気穴 (内側をくり抜いて煙突らしく見せます)
            translate([0, 0, 1])
                cylinder(d=3.2, h=3);
        }
    }
}

// 客室パノラマ窓枠
module cabin_window_frame() {
    difference() {
        // 外枠
        hull() {
            translate([-3.2, -3.7, 0]) cylinder(r=1, h=1.2);
            translate([ 3.2, -3.7, 0]) cylinder(r=1, h=1.2);
            translate([-3.2,  3.7, 0]) cylinder(r=1, h=1.2);
            translate([ 3.2,  3.7, 0]) cylinder(r=1, h=1.2);
        }
        // 内側
        hull() {
            translate([-2.5, -3, -1]) cylinder(r=1, h=4);
            translate([ 2.5, -3, -1]) cylinder(r=1, h=4);
            translate([-2.5,  3, -1]) cylinder(r=1, h=4);
            translate([ 2.5,  3, -1]) cylinder(r=1, h=4);
        }
    }
    // 十字の窓格子
    translate([-0.4, -3.5, 0]) cube([0.8, 7, 0.8]);
    translate([-3, -0.4, 0]) cube([6, 0.8, 0.8]);
}


// -----------------------------------------------------------------------------
// 2. ハンドルモジュール (Steering Wheel)
// -----------------------------------------------------------------------------
module steering_wheel() {
    // 外輪 (床 z=12.5 とひさし z=29.0 の間を完璧に避ける直径11mmの超コンパクト設計)
    difference() {
        cylinder(d=11, h=2);
        translate([0, 0, -1])
            cylinder(d=8.2, h=4);
    }
    
    // 6本のスポークと外側の丸ノブ (長さを5.5mmに調整)
    for (a = [0:60:300]) {
        rotate([0, 0, a]) {
            translate([0, -0.6, 0])
                cube([5.5, 1.2, 1.2]);
            // スポーク先端のノブ
            translate([5.5, 0, 0.6])
                sphere(d=1.5);
        }
    }
    
    // 中央のボス
    cylinder(d=3.0, h=5.5);
    // スナップジョイント接続ピン (直径4.0mmのスナップフィット軸)
    translate([0, 0, 5.5])
        snap_pin(shaft_d=4.0, shaft_l=5.5, head_d=4.8, head_l=2.0, slit_w=1.0);
}

// スナップフィットピン本体
module snap_pin(shaft_d=4.0, shaft_l=5.5, head_d=4.8, head_l=2, slit_w=1.0) {
    difference() {
        union() {
            cylinder(d=shaft_d, h=shaft_l);
            translate([0, 0, shaft_l])
                cylinder(d1=head_d, d2=shaft_d-0.2, h=head_l);
        }
        translate([-slit_w/2, -head_d, shaft_l/3])
            cube([slit_w, head_d*2, shaft_l*(2/3) + head_l + 1]);
    }
}


// -----------------------------------------------------------------------------
// 3. ドアモジュール (Cabin Door)
// -----------------------------------------------------------------------------
module cabin_door() {
    // 原点 [0,0,0] はヒンジ軸の中心
    difference() {
        union() {
            // ドア本体
            translate([-11, -1.25, 0])
                cube([11, 2.5, 14.8]);
                
            // ヒンジ軸 (下から上までを貫く基本ソリッド)
            cylinder(d=4.5, h=14.8);
            
            // --- プリントインプレイス用ピボットピン (上下の回転軸) ---
            // 下ピボットピン (デッキの受け穴へ1.5mm突き出る、直径3.2mm)
            translate([0, 0, -1.5])
                cylinder(d=3.2, h=1.5);
                
            // 上ピボットピン (キャビン天井の受け穴へ1.5mm突き出る、直径3.2mm)
            translate([0, 0, 14.8])
                cylinder(d=3.2, h=1.5);
            
            // ドアノブ (外側 - ドアに0.35mm深くめり込ませ、ピンも太さ1.0mmにして強度を最大化)
            translate([-9, -2.1, 7.4])
                sphere(r=1.2);
            translate([-9, -0.5, 7.4])
                rotate([90, 0, 0])
                    cylinder(d=1.0, h=1.8);
                     
            // ドアノブ (内側 - ドアに0.35mm深くめり込ませて強固に合流)
            translate([-9, 2.1, 7.4])
                sphere(r=1.2);
            translate([-9, 2.3, 7.4])
                rotate([90, 0, 0])
                    cylinder(d=1.0, h=1.8);
        }
        
        // 【重要】フィラメントピン用の穴あけは不要になったため、完全廃止！
        
        // ドアのデザイン丸窓
        translate([-5.5, 0, 10])
            rotate([90, 0, 0])
                cylinder(d=4.5, h=4, center=true);
    }
    
    // ドア窓の格子ディテール
    translate([-5.5, 0, 10])
        rotate([90, 0, 0])
            difference() {
                cylinder(d=4.5, h=0.6, center=true);
                cylinder(d=3.3, h=2, center=true);
            }
    translate([-5.5 - 0.3, -0.3, 7.8])
        cube([0.6, 0.6, 4.4]);
    translate([-7.75, -0.3, 10 - 0.3])
        cube([4.5, 0.6, 0.6]);
}


// -----------------------------------------------------------------------------
// 4. 引き出しモジュール (Drawer)
// -----------------------------------------------------------------------------
module drawer() {
    // 原点 [0,0,0] はフロントプレートの内側合わせ面
    difference() {
        union() {
            // 引き出し本体ケース (カタマラン化で奥行きを22mmに拡張！)
            translate([0, -7.7, 0])
                cube([22, 15.4, 9.4]);
            
            // フロントプレート (厚さ1.5mm, 幅17mm, 高さ11mm)
            translate([-1.5, -8.5, -0.8])
                cube([1.5, 17, 11]);
                
            // 取っ手 (掴みやすい極小D型ハンドル)
            translate([-4.5, -4, 3.7])
                hull() {
                    translate([0, 0, 0]) cube([3, 1, 2]);
                    translate([0, 7, 0]) cube([3, 1, 2]);
                    translate([-1.5, 1.5, 0]) cube([1.5, 5, 2]);
                }
        }
        
        // 箱の内側をくり抜く (肉厚1.2mm)
        translate([1.2, -6.5, 1.2])
            cube([22, 13, 8.2]);
            
        // お風呂用・水抜き穴 (底面に1箇所)
        translate([11, 0, -1])
            cylinder(d=2.0, h=3);
    }
}
