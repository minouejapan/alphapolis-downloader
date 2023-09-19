(*
  アルファポリス小説ダウンローダー[alphadl]

  アルファポリスはWinINetではページを全てダウンロードすることが出来ないため、IndyHTTP(TIdHTTP)を
  使用してダウンロードする

  3.1 2023/09/17  トップページの各話URLタグおよび各ページURLその他情報の構造が変更されたことと
                  Indyライブラリを使用したダウンロードにもDLページ数制限がかけられたため正常に
                  ダウンロード出来なくなったことから大幅修正してダウンロード出来るようにした
                  ・IndyライブラリからWinINetによるHTMLダウンロードに変更した。またこのことに
                    よってOpenSSLライブラリは不要となった
                  ・確実にダウンロードを完了させるため、ダウンロード制限がかかった場合は制限が
                    解除されるまで待機するようにした
  3.0 2023/07/30  DL開始ページを指定した場合のNaro2mobiに送るDLページ数が1少なかった不具合を修正した
  2.9 2023/07/24  オプション引数確認処理を変更し、DL開始ページ指定オプション-sを追加し
  2.8 2023/05/30  作者URL情報取得処理を追加した
  2.7 2023/04/28  表紙画像URLの先頭1文字に余分な文字が入る場合がある不具合を修正した
  2.6 2023/03/28  &#????;の処理を16進数2byte決め打ちから10進数でも変換できるように変更した
                  表紙画像URLの先頭1文字が欠落する不具合を修正した
  2.5 2023/02/27  &#x????;にエンコードされている‼等のUnicode文字をデコードする処理を追加した
                  識別タグの文字列長さを定数からLength(識別文字定数)に変更した
  2.4 2022/12/28  見出しの青空文庫タグを変更した
  2.3 2022/12/09  有料コンテンツ等本文が取得できなかった場合は代わりに本文に取得出来ませんでした
                  メッセージを挿入するようにした
  2.2 2022/10/29  トップページの作品タイトル装飾タグがh2からh1に変わったため検出文字列を修正した
  2.1 2022/08/07  タイトル名の先頭に連載状況（連載中・完結）を追加するようにした
  2.0 2022/05/25  起動時にOpenSSLライブラリがあるかどうかチェックするようにした
  1.9 2022/02/02  本文中に挿絵がある場合、挿絵以降の本文を取得出来なかった不具合を修正
      2021/12/15  GitHubに上げるためソースコードを整理した
  1.8 2021/10/07  エピソードが1話の場合にダウンロード出来なかった不具合を修正した
                  前書きがない場合ダウンロードに失敗する不具合を修正した
                  本文中に入ることがある&#x202A;&#x202C;コードを削除する処理を追加した
  1.7 2021/09/29  表示画像がno_imageの場合は挿入しないようにした
  1.6 2021/09/17  強調（丸傍点）タグ<em><span></span></em>の処理を追加
                  表紙画像があれば表紙タグを挿入するようにした
  1.51 2021/07/09 ログファイルへの出力順序が他と異なっていた不具合を修正した
  1.5 2021/07/03  Naro2mobiから起動した際に進捗状況をNaro2mobi側に知らせるようにした
  1.4 2021/06/30  小説本文内の特殊文字（例："<"を&lt;で表記るしているやつ）の処理を追加した
  1.3 2021/06/22  小説本文をより確実に取得するために識別するタグの処理を変更した
                  ダウンロードした小説のログファイルを作成するようにした
  1.2 2021/06/13  保存するテキストの文字コードがShift-JISだったのををUTF-8に変更した
                  進捗状況がわかるようにコンソールへの表示を変更した
  1.1 2021/05/30  各話ページを取得中に途中で終了する不具合を修正（識別タグの文字数を間違えていた）
                  埋め込み画像リンクを青空文庫風のタグに変換するようにした
  1.0 2021/05/27  Windows用のアルファポリス小説ダウンローダーがなかったためNaro2mobiのソースコードを
                  テンプレートとして作成した
*)
program alphadl;

{$APPTYPE CONSOLE}

{$R *.res}



{$R *.dres}

uses
  System.SysUtils,
  System.Classes,
  Windows,
  WinINet,
  WinAPI.Messages;

const
  // データ抽出用の識別タグ
  //STITLEB  = '<h2 class="title">';     // 小説表題 2022/10/28 表題タグがh2からh1に変わった？
  //STITLEE  = '</h2>';
  STITLEB  = '<h1 class="title">';     // 小説表題
  STITLEE  = '</h1>';
  SAUTHERB = '<div class="author">';   // 作者
  SAUTHERE = '</a>';
  SHEADERB = '<div class="abstract">'; // 前書き
  SHEADERE = '</div>';
  //SSTRURLB = '<div class="episode ">       <a href="';
  SSTRURLB = '<div class="episode ">    <a href="';
  SSTRURLE = '" >';
  SSTTLB   = '<span class="title"><span class="bookmark-dummy"></span>';
  SSTTLE   = '</span>';

  SCAPTB   = '<div class="chapter-title">';
  SCAPTE   = '</div>';
  SEPISB   = '<h2 class="episode-title">';
  SEPISE   = '</h2>';
  //SBODYB   = '<div class="text " id="novelBoby">';
  SBODYB   = '<div class="text " id="novelBody">';
  SBODYE   = '</div>';
  SERRSTR  = '<div class="dots-indicator"';
  SPICTB   = '<div class="story-image"><a href="';
  SPICTM   = '" target="_blank"><img src="';
  SPICTE   = '" alt=""/></a></div>';
  SCOVERB  = '<div class="cover">';
  SCOVERE  = '" alt=""/>';
  SHEAD    = '<span class="content-status complete">';

  // 青空文庫形式
  AO_RBI = '｜';							// ルビのかかり始め(必ずある訳ではない)
  AO_RBL = '《';              // ルビ始め
  AO_RBR = '》';              // ルビ終わり
  AO_TGI = '［＃';            // 青空文庫書式設定開始
  AO_TGO = '］';              //        〃       終了
  AO_CPI = '［＃「';          // 見出しの開始
  AO_CPT = '」は大見出し］';	// 章
  AO_SEC = '」は中見出し］';  // 話
  AO_PRT = '」は小見出し］';

  AO_CPB = '［＃大見出し］';        // 2022/12/28 こちらのタグに変更
  AO_CPE = '［＃大見出し終わり］';
  AO_SEB = '［＃中見出し］';
  AO_SEE = '［＃中見出し終わり］';
  AO_PRB = '［＃小見出し］';
  AO_PRE = '［＃小見出し終わり］';

  AO_DAI = '［＃ここから';		// ブロックの字下げ開始
  AO_DAO = '［＃ここで字下げ終わり］';
  AO_DAN = '字下げ］';
  AO_PGB = '［＃改丁］';			// 改丁と会ページはページ送りなのか見開き分の
  AO_PB2 = '［＃改ページ］';	// 送りかの違いがあるがどちらもページ送りとする
  AO_BED = '［＃本文終わり］';// 本文終わり(Body End)
  AO_SM1 = '」に傍点］';			// ルビ傍点
  AO_SM2 = '」に丸傍点］';		// ルビ傍点 どちらもsesami_dotで扱う
  AO_EMB = '［＃丸傍点］';        // 横転開始
  AO_EME = '［＃丸傍点終わり］';  // 傍点終わり
  AO_KKL = '［＃ここから罫囲み］' ;     // 本来は罫囲み範囲の指定だが、前書きや後書き等を
  AO_KKR = '［＃ここで罫囲み終わり］';  // 一段小さい文字で表記するために使用する
  AO_END = '底本：';          // ページフッダ開始（必ずあるとは限らない）
  AO_PIB = '［＃リンクの図（';          // 画像埋め込み
  AO_PIE = '）入る］';        // 画像埋め込み終わり
  AO_CVB = '［＃表紙の図（';  // 表紙画像指定
  AO_CVE = '）入る］';        // 終わり

  CRLF   = #$0D#$0A;


// ユーザメッセージID
  WM_DLINFO  = WM_USER + 30;

var
  PageList,
  TextPage,
  LogFile: TStringList;
  Capter, URL, Path, FileName,
  NvStat, AuthURL, StartPage: string;
  TBuff: TStringList;
  hWnd: THandle;
  CDS: TCopyDataStruct;
  StartN: integer;
  DlCnt: integer;

// WinINetを用いたHTMLファイルのダウンロード
function LoadFromHTML(URLadr: string): string;
var
  hSession    : HINTERNET;
  hService    : HINTERNET;
  dwBytesRead : DWORD;
  dwFlag      : DWORD;
  lpBuffer    : PChar;
  RBuff       : TMemoryStream;
  TBuff       : TStringList;
begin
  Result   := '';
  hSession := InternetOpen('WinINet', INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);

  if Assigned(hSession) then
  begin
    dwFlag   := INTERNET_FLAG_RELOAD;
    hService := InternetOpenUrl(hSession, PChar(URLadr), nil, 0, dwFlag, 0);
    if Assigned(hService ) then
    begin
      RBuff := TMemoryStream.Create;
      try
        lpBuffer := AllocMem(65536);
        try
          dwBytesRead := 65535;
          while True do
          begin
            if InternetReadFile(hService, lpBuffer, 65535,{SizeOf(lpBuffer),}dwBytesRead) then
            begin
              if dwBytesRead = 0 then
                break;
              RBuff.WriteBuffer(lpBuffer^, dwBytesRead);
            end else
              break;
          end;
        finally
          FreeMem(lpBuffer);
        end;
        TBuff := TStringList.Create;
        try
          RBuff.Position := 0;
          TBuff.LoadFromStream(RBuff, TEncoding.UTF8);
          Result := TBuff.Text;
        finally
          TBuff.Free;
        end;
      finally
        RBuff.Free;
      end;
    end;
    InternetCloseHandle(hService);
  end;
end;

// HTMLテキスト内のCR/LF(#$0D#$0A)を除去しTAB文字を半角スペースに変換する
function ElimCRLF(Base: string): string;
var
  tmp: string;
begin
  tmp := StringReplace(Base, #$0D, '', [rfReplaceAll]);
  tmp := StringReplace(tmp,  #$0A, '', [rfReplaceAll]);
  tmp := StringReplace(tmp,  #$09, ' ', [rfReplaceAll]);
  Result := tmp;
end;

// 指定された文字列の前と後のスペース(' '/'　'/#$20/#$09/#$0D/#$0A)を除去する
// '　　文字　列　　' → '文字　列'
function TrimSpace(Base: string): string;
var
  p: integer;
  c: char;
begin
  while True do
  begin
    if Length(Base) = 0 then
      Break;
    c := Base[1];
    if Pos(c, ' 　'#$09#$0D#$0A) > 0 then
      Delete(Base, 1, 1)
    else
      Break;
  end;
  while True do
  begin
    p := Length(Base);
    if p = 0 then
      Break;
    c := Base[p];
    if Pos(c, ' 　'#$09#$0D#$0A) > 0 then
      Delete(Base, p, 1)
    else
      Break;
  end;
  Result := Base;
end;

// 本文の改行タグを削除する
function ChangeBRK(Base: string): string;
begin
  Result := StringReplace(Base, '<br />', '', [rfReplaceAll]);
end;

// 本文の青空文庫ルビ指定に用いられる文字があった場合誤作動しないように青空文庫代替表記に変換する(2022/3/25)
function ChangeAozoraTag(Base: string): string;
var
  tmp: string;
begin
  tmp := StringReplace(Base, '《', '※［＃始め二重山括弧、1-1-52］',  [rfReplaceAll]);
  tmp := StringReplace(tmp,  '》', '※［＃終わり二重山括弧、1-1-53］',  [rfReplaceAll]);
  tmp := StringReplace(tmp,  '｜', '※［＃縦線、1-1-35］',   [rfReplaceAll]);
  Result := tmp;
end;

// 本文のルビタグを青空文庫形式に変換する
function ChangeRuby(Base: string): string;
var
  tmp: string;
begin
  tmp := StringReplace(Base, '<ruby>',        AO_RBI, [rfReplaceAll]);
  tmp := StringReplace(tmp,  '<rt>',          AO_RBL, [rfReplaceAll]);
  tmp := StringReplace(tmp,  '</rt></ruby>',  AO_RBR, [rfReplaceAll]);
  Result := tmp;
end;

// 本文の強調タグ(<em><span></span></em>)を青空文庫形式に変換する
function ChangeEm(Base: string): string;
var
  tmp: string;
begin
  tmp := StringReplace(Base, '<em>',          AO_EMB, [rfReplaceAll]);
  tmp := StringReplace(tmp,  '</em>',         AO_EME, [rfReplaceAll]);
  tmp := StringReplace(tmp,  '<span>',        '',     [rfReplaceAll]);
  tmp := StringReplace(tmp,  '</span>',       '',     [rfReplaceAll]);
  Result := tmp;
end;

// Delphi XE2ではPos関数に検索開始位置を指定出来ないための代替え
function PosN(SubStr, Str: string; StartPos: integer): integer;
var
  tmp: string;
  p: integer;
begin
  tmp := Copy(Str, StartPos, Length(Str));
  p := Pos(SubStr, tmp);
  if p > 0 then
    Result := p + StartPos - 1  // 1ベーススタートのため1を引く
  else
    Result := 0;
end;

// HTML特殊文字の処理
// 1)エスケープ文字列 → 実際の文字
// 2)&#x????; → 通常の文字
function Restore2RealChar(Base: string): string;
var
  tmp, cd: string;
  p, p2, w: integer;
  ch: Char;
begin
  // エスケープされた文字
  tmp := StringReplace(Base, '&lt;',      '<',  [rfReplaceAll]);
  tmp := StringReplace(tmp,  '&gt;',      '>',  [rfReplaceAll]);
  tmp := StringReplace(tmp,  '&quot;',    '"',  [rfReplaceAll]);
  tmp := StringReplace(tmp,  '&nbsp;',    ' ',  [rfReplaceAll]);
  tmp := StringReplace(tmp,  '&yen;',     '\',  [rfReplaceAll]);
  tmp := StringReplace(tmp,  '&brvbar;',  '|',  [rfReplaceAll]);
  tmp := StringReplace(tmp,  '&copy;',    '©',  [rfReplaceAll]);
  tmp := StringReplace(tmp,  '&amp;',     '&',  [rfReplaceAll]);
  // &#????;にエンコードされた文字をデコードする(2023/3/19)
  p := Pos('&#', tmp);
  while p > 0 do
  begin
    Delete(tmp, p, 2);
    p2 := PosN(';', tmp, p);
    if p2 = 0 then
      Break;
    cd := Copy(tmp, p, p2 - p);
    Delete(tmp, p, p2 - p + 1);
    // 16進数
    if cd[1] = 'x' then
    begin
      Delete(cd, 1, 1);
      w := StrToInt('$' + cd);
    // 10進数
    end else
      w := StrToInt(cd);
    ch := Char(w);
    Insert(ch, tmp, p);
    p := Pos('&#', tmp);
  end;

  Result := tmp;
end;

// 埋め込まれた画像リンクを青空文庫形式に変換する
// 但し、画像ファイルはダウンロードせずにリンク先をそのまま埋め込む
function ChangeImage(Base: string): string;
var
  p, p2: integer;
  lnk: string;
begin
  p := Pos(SPICTB, Base);
  while p > 0 do
  begin
    Delete(Base, p, Length(SPICTB));
    p2 := Pos(SPICTM, Base);
    if p2 > 1 then
    begin
      Delete(Base, p, p2 - p + Length(SPICTM));
      p2 := Pos(SPICTE, Base);
      if p2 > 1 then
      begin
        lnk := Copy(Base, p, p2 - p);
        Delete(Base, p, p2 - p + Length(SPICTE));
      end;
      Insert(AO_PIE, Base, p);
      Insert(lnk, Base, p);
      Insert(AO_PIB, Base, p);
    end else
      p := p + Length(SPICTB) + 1;
    p := Pos(SPICTB, Base);
  end;
  Result := Base;
end;

// タイトル名をファイル名として使用出来るかどうかチェックし、使用不可文字が
// あれば修正する('-'に置き換える)
// フォルダ名の最後が'.'の場合、フォルダ作成時に"."が無視されてフォルダ名が
// 見つからないことになるため'.'も'-'で置き換える(2019/12/20)
function PathFilter(PassName: string): string;
var
	i, l: integer;
  path: string;
  tmp: AnsiString;
  ch: char;
begin
  // ファイル名を一旦ShiftJISに変換して再度Unicode化することでShiftJISで使用
  // 出来ない文字を除去する
  tmp := AnsiString(PassName);
	path := string(tmp);
  l :=  Length(path);
  for i := 1 to l do
  begin
  	ch := Char(path[i]);
    if Pos(ch, '\/;:*?"<>|. '+#$09) > 0 then
      path[i] := '-';
  end;
  Result := path;
end;

// 小説本文をHTMLから抜き出して整形する
function ParsePage(Page: string): Boolean;
var
  sp, ep: integer;
  capt, subt, body: string;
begin
  Result := False;

  Page := ChangeAozoraTag(Page);  // 最初に青空文庫のルビタグ文字｜《》を変換する

  //Page := ElimCRLF(Page);
  sp := Pos(SCAPTB, Page);
  if sp > 1 then
  begin
    Delete(Page, 1, Length(SCAPTB) + sp - 1);
    ep := Pos(SCAPTE, Page);
    if ep > 1 then
    begin
      capt := Copy(Page, 1, ep - 1);
      capt := TrimSpace(capt);
      capt := Restore2RealChar(capt);
      if Capter = capt then
        capt := ''
      else
        Capter := capt;
      Delete(Page, 1, Length(SCAPTE) + ep - 1);
    end;
  end else
    capt := '';
  // 本文の終わりを</div>で検出するため、同様に</div>で終了する埋め込み画像を
  // 最初に処理しておく(2022/2/2)
  Page := ChangeImage(Page);

  sp := Pos(SEPISB, Page);
  if sp > 1 then
  begin
    Delete(Page, 1, Length(SEPISB) + sp - 1);
    ep := Pos(SEPISE, Page);
    if ep > 1 then
    begin
      subt := Copy(Page, 1, ep - 1);
      subt := TrimSpace(subt);
      subt := Restore2RealChar(subt);
      Delete(Page, 1, Length(SEPISB) + ep - 1);
      sp := Pos(SBODYB, Page);
      if sp > 1 then
      begin
        Delete(Page, 1, Length(SBODYB) + sp - 1);
        ep := Pos(SBODYE, Page);
        if ep > 1 then
        begin
          body := Copy(Page, 1, ep - 1);
          body := ChangeBRK(body);        // </ br>をCRLFに変換する
          body := ChangeRuby(body);       // ルビのタグを変換する
          body := ChangeEm(body);         // 強調（傍点）タグを変換する
          body := Restore2RealChar(body); // エスケースされた特殊文字を本来の文字に変換する

          if Length(capt) > 0 then
            TextPage.Add(AO_CPB + capt + AO_CPE);
          sp := Pos(SERRSTR, body);
          if sp > 0 then
          begin
            TextPage.Add(AO_SEB + subt + AO_SEE);
            TextPage.Add('★HTMLページ読み込みエラー');
            Result := True;
          end else begin
            TextPage.Add(AO_SEB + subt + AO_SEE);
            TextPage.Add(body);
            TextPage.Add('');
            TextPage.Add(AO_PB2);
            TextPage.Add('');
          end;
        end;
      end;
    end;
  end else begin
    TextPage.Add('本文を取得出来ませんでした.');
    TextPage.Add(AO_PB2);
  end;
end;

// 各話URLリストをもとに各話ページを読み込んで本文を取り出す
procedure LoadEachPage;
var
  i, n, cnt, sc: integer;
  RBuff: TMemoryStream;
  TBuff: TStringList;
  CSBI: TConsoleScreenBufferInfo;
  CCI: TConsoleCursorInfo;
  hCOutput: THandle;
begin
  RBuff := TMemoryStream.Create;
  try
    TBuff := TStringList.Create;
    try
      cnt := PageList.Count;
      hCOutput := GetStdHandle(STD_OUTPUT_HANDLE);
      GetConsoleScreenBufferInfo(hCOutput, CSBI);
      GetConsoleCursorInfo(hCOutput, CCI);
      Write('各話を取得中 [  0/' + Format('%3d', [cnt]) + ']');
      CCI.bVisible := False;
      SetConsoleCursorInfo(hCoutput, CCI);
      if StartN > 0 then
        i := StartN - 1
      else
        i := 0;
      n := 1;
      sc := cnt - i;

      while i < cnt do
      begin
        TBuff.Text := LoadFromHTML(PageList.Strings[i]);
        while Pos(SERRSTR, TBuff.Text) > 0 do
        begin
          // ダウンロード制限にかかった場合は10秒待機して再ダウンロードを繰り返す
          Sleep(10000);
          TBuff.Text := LoadFromHTML(PageList.Strings[i]);
        end;
        SetConsoleCursorPosition(hCOutput, CSBI.dwCursorPosition);
        Write('各話を取得中 [' + Format('%3d', [i + 1]) + '/' + Format('%3d', [cnt]) + '(' + Format('%d', [(n * 100) div sc]) + '%)]');
        if hWnd <> 0 then
          SendMessage(hWnd, WM_DLINFO, i, 1);
        ParsePage(TBuff.Text);
        if (TBuff.Text = '') or (Pos(SERRSTR, TBuff.Text) > 0) then
        begin
          TextPage.Add('本文を取得出来ませんでした.');
          TextPage.Add(AO_PB2);
        end;
        Inc(i);
        Inc(n);
      end;
    finally
      TBuff.Free;
    end;
  finally
    RBuff.Free;
  end;
  CCI.bVisible := True;
  SetConsoleCursorInfo(hCoutput, CCI);
  Writeln('');
end;

// トップページからタイトル、作者、前書き、各話情報を取り出す
procedure ParseCapter(MainPage: string);
var
  sp, ep: integer;
  ss, ts, title, auther, fn, sendstr, cv: string;
  conhdl: THandle;
begin
  Write('小説情報を取得中 ' + URL + ' ... ');

  // タイトル名
  sp := Pos(STITLEB, MainPage);
  if sp > 0 then
  begin
    Delete(MainPage, 1, sp + Length(STITLEB) - 1);
    sp := Pos(STITLEE, MainPage);
    if sp > 1 then
    begin
      ss := Copy(MainPage, 1, sp - 1);
      while (ss[1] <= ' ') do
        Delete(ss, 1, 1);
      // タイトル名からファイル名に使用できない文字を除去する
      title := PathFilter(Restore2RealChar(ss));
      // 引数に保存するファイル名を指定していなかった場合、タイトル名からファイル名を作成する
      if Length(Filename) = 0 then
      begin
        fn := title;
        if Length(fn) > 26 then
          Delete(fn, 27, Length(fn) - 26);
        if StartPage <> '' then
          fn := fn + '(' + StartPage + ')';

        Filename := Path + fn + '.txt';
      end;
      // タイトル名に"完結"が含まれていなければ先頭に小説の連載状況を追加する
      if Pos('完結', title) = 0 then
        title := NvStat + title;
      // タイトル名を保存
      TextPage.Add(title);
      LogFile.Add('タイトル：' + title);
      Delete(MainPage, 1, sp + Length(STITLEE));
      // 作者名
      AuthURL := '';
      sp := Pos(SAUTHERB, MainPage);
      if sp > 1  then
      begin
        Delete(MainPage, 1, sp + Length(SAUTHERB) - 1);
        ep := Pos(SAUTHERE, MainPage);
        if ep > 1 then
        begin
          ts := Copy(MainPage, 1, ep - 1);
          sp := Pos('<a href="', ts);
          Delete(ts, 1, sp + Length('<a href="') - 1);
          sp := Pos('">', ts);
          AuthURL := 'https://www.alphapolis.co.jp' + Copy(ts, 1, sp - 1);
          Delete(ts, 1, sp + 1);
          auther := ts;
          // 作者名を保存
          TextPage.Add(auther);
          TextPage.Add('');
          TextPage.Add(AO_PB2);
          TextPage.Add('');
          LogFile.Add('作者　　：' + auther);
          if AuthURL <> '' then
            LogFile.Add('作者URL : ' + AuthURL);
          Delete(MainPage, 1, ep + Length(SAUTHERE));
          // 前書き（あらすじ）
          sp := Pos(SHEADERB, MainPage);
          if sp > 1 then
          begin
            Delete(MainPage, 1, sp + Length(SHEADERB) - 1);
            ep := Pos(SHEADERE, MainPage);
            if ep > 1 then
            begin
              ts := Copy(MainPage, 1, ep - 1);
              ts := ChangeBRK(ts);
              TextPage.Add(AO_KKL);
              TextPage.Add(ts);
              TextPage.Add(AO_KKR);
              TextPage.Add(AO_PB2);
              LogFile.Add('あらすじ：');
              LogFile.Add(ts);
            end;
          end;
          // 各ページ情報を取得
          // #$0D#$0Aを削除する
          MainPage := ElimCRLF(MainPage);
          sp := Pos(SSTRURLB, MainPage);
          while sp > 1 do
          begin
            Delete(MainPage, 1, sp + Length(SSTRURLB) - 1);
            ep := Pos(SSTRURLE, MainPage);
            if ep > 1 then
            begin
              ts := Copy(MainPage, 1, ep - 1);
              Delete(MainPage, 1, ep + Length(SSTRURLE) - 1);
              sp := Pos(SSTTLB, MainPage);
              if sp > 1 then
              begin
                Delete(MainPage, 1, Length(SSTTLB) + sp - 1);
                ep := Pos(SSTTLE, MainPage);
                if ep > 1 then
                begin
                  ss := Copy(MainPage, 1, ep - 1);
                  Delete(MainPage, 1, Length(SSTTLE) + ep - 1);
                  PageList.Add(ts);
                  sp := Pos(SSTRURLB, MainPage);
                end else
                  Break;
              end else
                Break;
            end else
              Break;
          end;
          // 表紙画像をチェック
          sp := Pos(SCOVERB, MainPage);
          if sp > 1 then
          begin
            Delete(MainPage, 1, sp + Length(SCOVERB));
            sp := Pos('<img src="', MainPage);
            if sp > 0 then
            begin
              Delete(MainPage, 1, sp + Length('<img src="') - 1);
              ep := Pos('">', MainPage);
              cv := Copy(MainPage, 1, ep - 1);
              if Pos('alphapolis.co.jp/img/books/no_image/', cv) = 0 then
                TextPage.Insert(2, AO_CVB + cv + AO_CVE);
            end;
          end;
          Writeln(IntToStr(PageList.Count) + ' 話の情報を取得しました.');
          // Naro2mobiから呼び出された場合は進捗状況をSendする
          if hWnd <> 0 then
          begin
            conhdl := GetStdHandle(STD_OUTPUT_HANDLE);
            sendstr := title + ',' + auther;
            Cds.dwData := PageList.Count - StartN + 1;
            Cds.cbData := (Length(sendstr) + 1) * SizeOf(Char);
            Cds.lpData := Pointer(sendstr);
            SendMessage(hWnd, WM_COPYDATA, conhdl, LPARAM(Addr(Cds)));
          end;
        end;
      end;
    end;
  end;
end;

// 小説の連載状況をチェックする
function GetNovelStatus(MainPage: string): string;
var
  str: string;
  p: integer;
begin
  Result := '';
  p := Pos(SHEAD, MainPage);
  if p > 0 then
  begin
    str := Copy(MainPage, p + Length(SHEAD), 20);
    if Pos('連載中', str) > 0 then
      Result := '【連載中】'
    else if Pos('完結', str) > 0 then
      Result := '【完結】';
  end;
end;

var
  i: integer;
  op: string;
  st, et: TTime;

begin
  if ParamCount = 0 then
  begin
    Writeln('');
    Writeln('alphadl ver3.1 2023/9/19 (c) INOUE, masahiro.');
    Writeln('  使用方法');
    Writeln('  alphadl [-sDL開始ページ番号] 小説トップページのURL [保存するファイル名(省略するとタイトル名で保存します)]');
    Exit;
  end;
  st := Now;
  hWnd := 0;

  Path := ExtractFilePath(ParamStr(0));

  // オプション引数取得
  for i := 0 to ParamCount - 1 do
  begin
    op := ParamStr(i + 1);
    // Naro2mobiのWindowsハンドル
    if Pos('-h', op) = 1 then
    begin
      Delete(op, 1, 2);
      try
        hWnd := StrToInt(op);
      except
        Writeln('Error: Invalid Naro2mobi Handle.');
        ExitCode := -1;
        Exit;
      end;
    // DL開始ページ番号
    end else if Pos('-s', op) = 1 then
    begin
      Delete(op, 1, 2);
      StartPage := op;
      try
        StartN := StrToInt(op);
      except
        Writeln('Error: Invalid Start Page Number.');
        ExitCode := -1;
        Exit;
      end;
    // 作品URL
    end else if Pos('https:', op) = 1 then
    begin
      URL := op;
    // それ以外であれば保存ファイル名
    end else begin
      FileName := op;
      if UpperCase(ExtractFileExt(op)) <> '.TXT' then
        FileName := FileName + '.txt';
    end;
  end;

  if Pos('https://www.alphapolis.co.jp/novel/', URL) = 0 then
  begin
    Writeln('小説のURLが違います.');
    Exit;
  end;

  Capter := '';
  TBuff := TStringList.Create;
  try
    TBuff.Text := LoadFromHTML(URL);
    if TBuff.Text <> '' then
    begin
      PageList := TStringList.Create;
      TextPage := TStringList.Create;
      LogFile  := TStringList.Create;
      LogFile.Add(URL);
      try
        NvStat := GetNovelStatus(TBuff.Text); // 小説の連載状況を取得
        ParseCapter(TBuff.Text);
        if PageList.Count > 0 then
        begin
          // 各話ページを読み込む
          DlCnt := 0;
          LoadEachPage;
          try
            TextPage.SaveToFile(Filename, TEncoding.UTF8);
            LogFile.SaveToFile(ChangeFileExt(FileName, '.log'), TEncoding.UTF8);
            Writeln(Filename + ' に保存しました.');
          except
            Writeln('ファイルの保存に失敗しました.');
            ExitCode := 1;
          end;
        end else begin
          Writeln(URL + '：トップページの目次情報を取得出来ませんでした.');
          ExitCode := 1;
        end;
      finally
        PageList.Free;
        TextPage.Free;
        LogFile.Free;
      end;
    end else begin
      Writeln(URL + '：トップページをダウンロード出来ませんでした.');
      ExitCode := 1;
    end;
  finally
    TBuff.Free;
  end;
  et := Now - st;
  Writeln('時間: ' + FormatDateTime('hh:nn:ss', et));
end.
