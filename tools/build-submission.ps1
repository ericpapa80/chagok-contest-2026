$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path $PSScriptRoot -Parent
$temp=Join-Path ([IO.Path]::GetTempPath()) 'chagok-video-edit';New-Item -ItemType Directory -Force -Path $temp | Out-Null
function Text($g,$text,$size,$x,$y,$color='White'){$f=[Drawing.Font]::new('Malgun Gothic',$size,[Drawing.FontStyle]::Regular,[Drawing.GraphicsUnit]::Pixel);$b=[Drawing.SolidBrush]::new([Drawing.ColorTranslator]::FromHtml($color));$g.DrawString($text,$f,$b,$x,$y);$f.Dispose();$b.Dispose()}
function ScreenPath($n){(Get-ChildItem -LiteralPath "$root/screens" -Filter ('{0:D2}_*.png' -f $n)).FullName}
$scenes=@(@(1,'차곡차곡 · 함께 달린 하루가 기억이 됩니다'),@(2,'01  기록 · 앞유리 너머 순간을 남기다'),@(6,'02  오늘의 기록 · 하루를 시간순으로'),@(7,'03  다시 보기 · 기억에 가까이'),@(10,'04  제목 편집 · 우리만의 이름으로'),@(18,'05  한마디 · 그때의 마음을 담다'),@(21,'06  귀갓길 · 하루 이야기를 듣다'),@(30,'07  갤러리 · 여러 날의 기억을 한눈에'),@(35,'08  영상 보관함 · 다시 꺼내 보는 순간'),@(37,'09  지도 · 장소와 기억을 잇다'),@(40,'10  회상 · 익숙한 길에서 만난 지난날'),@(46,'차곡차곡 · 기록에서 회상까지'))
$idx=0;$concat=@()
foreach($s in $scenes){
 $bmp=[Drawing.Bitmap]::new(1920,1080);$g=[Drawing.Graphics]::FromImage($bmp);$g.Clear([Drawing.Color]::FromArgb(17,29,26));$g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
 $im=[Drawing.Image]::FromFile((ScreenPath $s[0]));$g.DrawImage($im,160,100,1600,900);$im.Dispose();Text $g $s[1] 38 160 31 '#E9F0E8';Text $g '화면 캡처 기반 흐름 시연 · AI 실사 풍경 적용 시안 · 실제 앱 실행 녹화 아님' 23 160 1020 '#ABC3B6'
 $frame="$temp/demo-$idx.png";$bmp.Save($frame);$g.Dispose();$bmp.Dispose();$clip="$temp/demo-$idx.mp4"
 & ffmpeg -hide_banner -loglevel error -y -loop 1 -i $frame -t 5 -vf 'fps=30,fade=t=in:st=0:d=0.25,fade=t=out:st=4.75:d=0.25,format=yuv420p' -c:v libx264 -preset fast -crf 21 -an $clip
 if($LASTEXITCODE){throw 'Demo render failed'};$concat+="file '$($clip.Replace('\','/'))'";$idx++
}
$concat | Set-Content -LiteralPath "$temp/demo-list.txt" -Encoding utf8
& ffmpeg -hide_banner -loglevel error -y -f concat -safe 0 -i "$temp/demo-list.txt" -c copy -movflags +faststart "$root/videos/chagok-demo-60s.mp4"
$sources=Get-ChildItem -LiteralPath "$root/videos/source" -Filter '*.mp4' | Sort-Object Name
$titles=@('함께 달린 하루','순간은 차곡차곡','한마디를 더하면','우리만의 이야기가','익숙한 길 위에서','차곡차곡')
$subs=@('스쳐 지나간 풍경을 기억으로','오늘의 기록 · 시간순 카드','그날의 목소리, 그때의 마음','귀갓길에 다시 만나는 하루','다시 꺼내 보는 소중한 순간','기록 · 이야기 · 회상')
$screenNums=@(0,6,0,21,0,30);$shortList=@()
for($i=0;$i -lt 6;$i++){
 $bmp=[Drawing.Bitmap]::new(1080,1920);$g=[Drawing.Graphics]::FromImage($bmp);$g.Clear([Drawing.Color]::Transparent)
 if($i%2 -eq 1){$g.Clear([Drawing.Color]::FromArgb(17,29,26));$im=[Drawing.Image]::FromFile((ScreenPath $screenNums[$i]));$g.DrawImage($im,30,620,1020,574);$im.Dispose();Text $g '화면 캡처 기반 앱 흐름 시안' 28 68 1240 '#ABC3B6'}
 $dark=[Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(145,9,22,18));$g.FillRectangle($dark,0,0,1080,430);$g.FillRectangle($dark,0,1630,1080,290);$dark.Dispose()
 Text $g '차곡차곡  /  JOURNEY TO MEMORY' 27 68 94 '#D7E7D9';Text $g $titles[$i] 66 68 195;Text $g $subs[$i] 34 68 305 '#E3EBDD';Text $g '함께한 순간을, 오래도록' 42 68 1682;Text $g 'AI 연출 풍경 · 화면 시안 기반 소개 영상' 25 68 1790 '#D7E7D9'
 $overlay="$temp/short-$i.png";$bmp.Save($overlay);$g.Dispose();$bmp.Dispose();$clip="$temp/short-$i.mp4"
 if($i%2 -eq 0){$src=$sources[[int]($i/2)].FullName;& ffmpeg -hide_banner -loglevel error -y -i $src -i $overlay -filter_complex '[0:v]scale=1080:1920,fps=30[b];[b][1:v]overlay=0:0,format=yuv420p[v]' -map '[v]' -t 5 -an -c:v libx264 -preset fast -crf 21 $clip}
 else{& ffmpeg -hide_banner -loglevel error -y -loop 1 -i $overlay -t 5 -vf 'fps=30,format=yuv420p' -an -c:v libx264 -preset fast -crf 21 $clip}
 if($LASTEXITCODE){throw 'Short render failed'};$shortList+="file '$($clip.Replace('\','/'))'"
}
$shortList | Set-Content -LiteralPath "$temp/short-list.txt" -Encoding utf8
& ffmpeg -hide_banner -loglevel error -y -f concat -safe 0 -i "$temp/short-list.txt" -c copy -movflags +faststart "$root/videos/chagok-short-30s.mp4"
Write-Output 'SUBMISSION VIDEOS COMPLETE'
