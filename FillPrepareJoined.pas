implementation

type
  TOrmHack = class(TOrm);
  TOrmFillHack = class(TOrmFill);
  
procedure FillPrepareJoined(const AServer: IRestOrmServer; AValue: TOrm;
  const AFormatSQLJoin: RawUtf8; const AParamsSQLJoin, ABoundsSQLJoin: array of const);
var
  i, n: Integer;
  props: TOrmModelProperties;
  tbl: TOrmTable;
  ormClass: TOrmClass;
  instance: TOrm;
  sql: RawUtf8;
  fill: TOrmFillHack;
begin
  ormClass := POrmClass(AValue)^;
  props := AServer.Model.Props[ormClass];

  sql := props.sql.SelectAllJoined;
  sql := StringReplaceAll(sql, '`',     '''');
  sql := StringReplaceAll(sql, 'RowID', 'ID', True);
  if AFormatSQLJoin <> '' then
    sql := sql + FormatSql(SqlFromWhere(AFormatSQLJoin), AParamsSQLJoin, ABoundsSQLJoin);

  tbl := TRestStorage(AServer.GetStorage(ormClass)).ExecuteList([], sql);
  if tbl = nil then
    Exit;

  fill := TOrmFillHack.Create;
  TOrmHack(AValue).fFill := fill;
  fill.fJoinedFields := True;
  fill.fTable := tbl;
  fill.fTable.OwnerMustFree := True;
  fill.fFillCurrentRow := 1; // point to first data row (0 is field names)

  n := 0;
  with props.props do
    begin // follow sql.SelectAllJoined columns
      fill.AddMapSimpleFields(AValue, SimpleFields, n);
      for i := 1 to Length(JoinedFieldsTable) - 1 do
        begin
          instance := JoinedFieldsTable[i].Create;
          JoinedFields[i - 1].SetInstance(AValue, instance);
          fill.AddMapSimpleFields(instance, JoinedFieldsTable[i].OrmProps.SimpleFields, n);
        end;
    end;
end;
