(*
  アルファポリス小説ダウンローダー[alphadl]

  アルファポリスはWinINetではページを全てダウンロードすることが出来ないため、IndyHTTP(TIdHTTP)を
  使用してダウンロードする

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
program alpha_dl;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils, System.Classes, Windows, WinAPI.Messages;

const
  // トップページ
  STITLEB  = '<h2 class="title">';     // 小説表題
  STITLEE  = '</h2>';
  SAUTHERB = '<div class="author">';   // 作者
  SAUTHERE = '</a>';
  SHEADERB = '<div class="abstract">'; // 前書き
  SHEADERE = '</div>';
  SSTRURLB = '<div class="episode ">							<a href="';
  SSTRURLE = '" >';
  SSTTLB   = '<span class="title"><span class="bookmark-dummy"></span>';
  SSTTLE   = '</span>';
  SCAPTB   = '<div class="chapter-title">';
  SCAPTE   = '</div>';
  SEPISB   = '<h2 class="episode-title">';
  SEPISE   = '</h2>';
  SBODYB   = '<div class="text " id="novelBoby">';
  SBODYE   = '</div>';
  SERRSTR  = '<div class="dots-indicator" id="LoadingEpisode">';
  SPICTB   = '<div class="story-image"><a href="';
  SPICTM   = '" target="_blank"><img src="';
  SPICTE   = '" alt=""/></a>';

  ITITLEB  = 18;     // 小説表題
  ITITLEE  = 5;
  IAUTHERB = 20;   // 作者
  IAUTHERE = 4;
  IHEADERB = 22; // 前書き
  IHEADERE = 6;
  ISTRURLB = 38;
  ISTRURLE = 3;
  ISTTLB   = 56;
  ISTTLE   = 7;
  ICAPTB   = 27;
  ICAPTE   = 6;
  IEPISB   = 26;
  IEPISE   = 5;
  IBODYB   = 34;
  IBODYE   = 6;
  IPICTB   = 34;
  IPICTM   = 28;
  IPICTE   = 14;

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
  AO_DAI = '［＃ここから';		// ブロックの字下げ開始
  AO_DAO = '［＃ここで字下げ終わり］';
  AO_DAN = '字下げ］';
  AO_PGB = '［＃改丁］';			// 改丁と会ページはページ送りなのか見開き分の
  AO_PB2 = '［＃改ページ］';	// 送りかの違いがあるがどちらもページ送りとする
  AO_SM1 = '」に傍点］';			// ルビ傍点
  AO_SM2 = '」に丸傍点］';		// ルビ傍点 どちらもsesami_dotで扱う
  AO_KKL = '［＃ここから罫囲み］' ;     // 本来は罫囲み範囲の指定だが、前書きや後書き等を
  AO_KKR = '［＃ここで罫囲み終わり］';  // 一段小さい文字で表記するために使用する
  AO_END = '底本：';          // ページフッダ開始（必ずあるとは限らない）
  AO_PIB = '［＃リンクの図（';          // 画像埋め込み
  AO_PIE = '）入る］';        // 画像埋め込み終わり

  CRLF   = #$0D#$0A;

{ 青空文庫形式

  テキストヘッダ
		作品の表題
		原作の表題（翻訳作品で、底本に記載のある場合）
		副題（副題がある場合）
		原作の副題（副題がある翻訳作品で、底本に記載のある場合）
		著者名
		翻訳者名（翻訳の場合）

	ルビ
  	<ruby><rb>亜米利加</rb><rp>（</rp><rt>アメリカ</rt><rp>）</rp></ruby>
  	亜米利加《アメリカ》
}

// ユーザメッセージID
  WM_DLINFO  = WM_USER + 30;

type
  TLoadHTMLbyIndy = function(URLAdr: string; var HTMLText: WideString): Boolean; stdcall;


var
  PageList,
  TextPage,
  LogFile: TStringList;
  DllPath, Capter, URL, Path, FileName, strhdl: string;
  TBuff: TStringList;
  hWnd, dllWnd: THandle;
  CDS: TCopyDataStruct;
  LoadHTMLbyIndy: TLoadHTMLbyIndy;


// HTMLファイルのダウンロード
// Indyを使用する場合
// https://www.alphapolis.co.jp/novel/925486466/69515570
function LoadHTML(URLAdr: string): string;
var
  htmltxt: WideString;
begin
  Result := '';
 if LoadHTMLByIndy(URLAdr, htmltxt) then
 begin
    //Writeln(htmltxt);
    Result := htmltxt;
  end;
end;

// HTMLテキスト内のCR/LF(#$0D#$0A)を除去する
function ElimCRLF(Base: string): string;
begin
  Result := StringReplace(Base, #$0D#$0A, '', [rfReplaceAll]);
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
    if (c = ' ') or (c = '　') or (c = #$09) or (c = #$0D) or (c = #$0A) then
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
    if (c = ' ') or (c = '　') or (c = #$09) or (c = #$0D) or (c = #$0A) then
      Delete(Base, p, 1)
    else
      Break;
  end;
  Result := Base;
end;

// 本文の改行タグを改行コードに変換する
function ChangeBRK(Base: string): string;
begin
  Result := StringReplace(Base, '<br />', '', [rfReplaceAll]);
end;

// 本文の青空文庫ルビタグ文字を代替文字に変換する
function ChangeAozoraTag(Base: string): string;
var
  tmp: string;
begin
  tmp := StringReplace(Base, '《', '『',  [rfReplaceAll]);
  tmp := StringReplace(tmp,  '》', '』',  [rfReplaceAll]);
  tmp := StringReplace(tmp,  '｜', '‖',   [rfReplaceAll]);
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

// HTML特殊文字の処理（実際の文字→エスケープ）
function Restore2RealChar(Base: string): string;
var
  tmp: string;
begin
  tmp := StringReplace(Base, '&lt;',      '<',  [rfReplaceAll]);
  tmp := StringReplace(tmp,  '&gt;',      '>',  [rfReplaceAll]);
  tmp := StringReplace(tmp,  '&amp;',     '&',  [rfReplaceAll]);
  tmp := StringReplace(tmp,  '&nbsp;',    ' ',  [rfReplaceAll]);
  tmp := StringReplace(tmp,  '&yen;',     '\',  [rfReplaceAll]);
  tmp := StringReplace(tmp,  '&brvbar;',  '|',  [rfReplaceAll]);
  tmp := StringReplace(tmp,  '&copy;',    '©',  [rfReplaceAll]);
  tmp := StringReplace(tmp,  '&quot;',    '"',  [rfReplaceAll]);
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
    Delete(Base, p, IPICTB);
    p2 := Pos(SPICTM, Base);
    if p2 > 1 then
    begin
      Delete(Base, p, p2 - p + IPICTM);
      p2 := Pos(SPICTE, Base);
      if p2 > 1 then
      begin
        lnk := Copy(Base, p, p2 - p);
        Delete(Base, p, p2 - p + IPICTE);
      end;
      Insert(AO_PIE, Base, p);
      Insert(lnk, Base, p);
      Insert(AO_PIB, Base, p);
    end;
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
function PersPage(Page: string): Boolean;
var
  sp, ep: integer;
  capt, subt, body: string;
begin
  Result := False;

  //Page := ElimCRLF(Page);
  sp := Pos(SCAPTB, Page);
  if sp > 1 then
  begin
    Delete(Page, 1, ICAPTB + sp - 1);
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
      Delete(Page, 1, ICAPTE + ep - 1);
      sp := Pos(SEPISB, Page);
      if sp > 1 then
      begin
        Delete(Page, 1, IEPISB + sp - 1);
        ep := Pos(SEPISE, Page);
        if ep > 1 then
        begin
          subt := Copy(Page, 1, ep - 1);
          subt := TrimSpace(subt);
          subt := Restore2RealChar(subt);
          Delete(Page, 1, IEPISB + ep - 1);
          sp := Pos(SBODYB, Page);
          if sp > 1 then
          begin
            Delete(Page, 1, IBODYB + sp - 1);
            ep := Pos(SBODYE, Page);
            if ep > 1 then
            begin
              body := Copy(Page, 1, ep - 1);
              body := ChangeBRK(body);        // </ br>をCRLFに変換する
              body := ChangeAozoraTag(body);  // 青空文庫のルビタグ文字｜《》を変換する
              body := ChangeRuby(body);       // ルビのタグを変換する
              body := ChangeImage(body);      // 埋め込み画像リンクを変換する
              body := Restore2RealChar(body); // エスケースされた特殊文字を本来の文字に変換する

              if Length(capt) > 0 then
                TextPage.Add(AO_CPI + capt + AO_CPT);

              sp := Pos(SERRSTR, body);
              if (sp > 0) and (sp < 10) then
              begin
                TextPage.Add(AO_CPI + subt + AO_SEC);
                TextPage.Add('★HTMLページ読み込みエラー');
                Result := True;
              end else begin
                TextPage.Add(AO_CPI + subt + AO_SEC);
                TextPage.Add(body);
                TextPage.Add('');
                TextPage.Add(AO_PB2);
                TextPage.Add('');
              end;
            end;
          end;
        end;
      end;
    end;
  end;
end;

// 各話URLリストをもとに各話ページを読み込んで本文を取り出す
procedure LoadEachPage;
var
  i, cnt: integer;
  TBuff: TStringList;
  CSBI: TConsoleScreenBufferInfo;
  CCI: TConsoleCursorInfo;
  hCOutput: THandle;
begin
  TBuff := TStringList.Create;
  try
    i := 0;
    cnt := PageList.Count;
    hCOutput := GetStdHandle(STD_OUTPUT_HANDLE);
    GetConsoleScreenBufferInfo(hCOutput, CSBI);
    GetConsoleCursorInfo(hCOutput, CCI);
    Write('各話を取得中 [  0/' + Format('%3d', [cnt]) + ']');
    CCI.bVisible := False;
    SetConsoleCursorInfo(hCoutput, CCI);
    while i < cnt do
    begin
      TBuff.Text := LoadHTML('https://www.alphapolis.co.jp' + PageList.Strings[i]);
      if TBuff.Text <> '' then
      begin
        PersPage(TBuff.Text);
        SetConsoleCursorPosition(hCOutput, CSBI.dwCursorPosition);
        Write('各話を取得中 [' + Format('%3d', [i]) + '/' + Format('%3d', [PageList.Count]) + '(' + Format('%d', [(i * 100) div cnt]) + '%)]');
        if hWnd <> 0 then
          SendMessage(hWnd, WM_DLINFO, i, 1);
      end;
      Inc(i);
    end;
  finally
    TBuff.Free;
  end;
  CCI.bVisible := True;
  SetConsoleCursorInfo(hCoutput, CCI);
  Writeln('');
end;

// トップページからタイトル、作者、前書き、各話情報を取り出す
procedure PersCapter(MainPage: string);
var
  sp, ep: integer;
  ss, ts, title, auther, fn, sendstr: string;
  conhdl: THandle;
begin
  Write('小説情報を取得中 ' + URL + ' ... ');
  // タイトル名
  sp := Pos(STITLEB, MainPage);
  if sp > 0 then
  begin
    Delete(MainPage, 1, sp + ITITLEB  - 1);
    sp := Pos(STITLEE, MainPage);
    if sp > 1 then
    begin
      ss := Copy(MainPage, 1, sp - 1);
      while (ss[1] <= ' ') do
        Delete(ss, 1, 1);
      // タイトル名からファイル名に使用できない文字を除去する
      title := PathFilter(ss);
      // 引数に保存するファイル名を指定していなかった場合、タイトル名からファイル名を作成する
      if Length(Filename) = 0 then
      begin
        fn := title;
        if Length(fn) > 26 then
          Delete(fn, 27, Length(fn) - 26);
        Filename := Path + fn + '.txt';
      end;
      // タイトル名を保存
      TextPage.Add(title);
      LogFile.Add('タイトル：' + title);
      Delete(MainPage, 1, sp + ITITLEE);
      // 作者名
      sp := Pos(SAUTHERB, MainPage);
      if sp > 1  then
      begin
        Delete(MainPage, 1, sp + IAUTHERB - 1);
        ep := Pos(SAUTHERE, MainPage);
        if ep > 1 then
        begin
          ts := Copy(MainPage, 1, ep - 1);
          sp := Pos('">', ts);
          Delete(ts, 1, sp + 1);
          auther := ts;
          // 作者名を保存
          TextPage.Add(auther);
          TextPage.Add('');
          TextPage.Add(AO_PB2);
          TextPage.Add('');
          LogFile.Add('作者　　：' + auther);
          Delete(MainPage, 1, ep + IAUTHERE);
          // 前書き（あらすじ）
          sp := Pos(SHEADERB, MainPage);
          if sp > 1 then
          begin
            Delete(MainPage, 1, sp + IHEADERB - 1);
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
              // #$0D#$0Aを削除する
              MainPage := ElimCRLF(MainPage);
              sp := Pos(SSTRURLB, MainPage);
              while sp > 1 do
              begin
                Delete(MainPage, 1, sp + ISTRURLB - 1);
                ep := Pos(SSTRURLE, MainPage);
                if ep > 1 then
                begin
                  ts := Copy(MainPage, 1, ep - 1);
                  Delete(MainPage, 1, ep + ISTRURLE - 1);
                  sp := Pos(SSTTLB, MainPage);
                  if sp > 1 then
                  begin
                    Delete(MainPage, 1, ISTTLB + sp - 1);
                    ep := Pos(SSTTLE, MainPage);
                    if ep > 1 then
                    begin
                      ss := Copy(MainPage, 1, ep - 1);
                      Delete(MainPage, 1, ISTTLE + ep - 1);
                      PageList.Add(ts);
                      sp := Pos(SSTRURLB, MainPage);
                    end else
                      Break;
                  end else
                    Break;
                end else
                  Break;
              end;
              Writeln(IntToStr(PageList.Count) + ' 話の情報を取得しました.');
              if hWnd <> 0 then
              begin
                conhdl := GetStdHandle(STD_OUTPUT_HANDLE);
                sendstr := title + ',' + auther;
                Cds.dwData := PageList.Count;
                Cds.cbData := (Length(sendstr) + 1) * SizeOf(Char);
                Cds.lpData := Pointer(sendstr);
                SendMessage(hWnd, WM_COPYDATA, conhdl, LPARAM(Addr(Cds)));
              end;
            end;
          end;
        end;
      end;
    end;
  end;
end;

begin
  if ParamCount = 0 then
  begin
    Writeln('');
    Writeln('alpha_dl ver1.0 2021/8/5 (c) INOUE, masahiro.');
    Writeln('  使用方法');
    Writeln('  alphadl 小説トップページのURL [保存するファイル名(省略するとタイトル名で保存します)]');
    Exit;
  end;
  hWnd := 0;

  Path := ExtractFilePath(ParamStr(0));
  URL := ParamStr(1);
  if ParamCount > 1 then
  begin
    FileName := ParamStr(2);
    if ParamCount = 3 then
    begin
      strhdl := ParamStr(3);
      if Pos('-h', strhdl) = 1 then
      begin
        Delete(strhdl, 1, 2);
        hWnd := StrToInt(strhdl);
      end;
    end;
  end else
    FileName := '';
  if Pos('https://www.alphapolis.co.jp/novel/', URL) = 0 then
  begin
    Writeln('小説のURLが違います.');
    Exit;
  end;

  DllPath := ExtractFilePath(ParamStr(0)) + 'idhtmllib.dll';
  DllWnd := LoadLibrary(PWideChar(DllPath));
  if DllWnd <> 0 then
    @LoadHTMLByIndy := GetProcAddress(DllWnd, 'LoadHTML');

  if @LoadHTMLByIndy = nil then
  begin
    Writeln('idhtmllib.dll読み込みエラー.');
    Exit;
  end;

  Capter := '';
  TBuff := TStringList.Create;
  try
    TBuff.Text := LoadHTML(URL);
    if TBuff.Text<> '' then
    begin
      PageList := TStringList.Create;
      TextPage := TStringList.Create;
      LogFile  := TStringList.Create;
      LogFile.Add(URL);
      try
        PersCapter(TBuff.Text);
        if PageList.Count > 1 then
        begin
          LoadEachPage;
          try
            TextPage.SaveToFile(Filename, TEncoding.UTF8);
            LogFile.SaveToFile(ChangeFileExt(FileName, '.log'), TEncoding.UTF8);
            Writeln(Filename + ' に保存しました.');
          except
            Writeln('ファイルの保存に失敗しました.');
          end;
        end else
          Writeln(URL + 'から情報を取得できませんでした.');
      finally
        PageList.Free;
        TextPage.Free;
      end;
    end else
      Writeln(URL + 'から情報を取得できませんでした.');
  finally
    TBuff.Free;
  end;
  FreeLibrary(DllWnd);
end.
