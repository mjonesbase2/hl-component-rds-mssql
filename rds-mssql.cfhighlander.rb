CfhighlanderTemplate do
  Name 'rds-mssql'
  Description "rds-mssql - #{component_version}"

  Parameters do
    ComponentParam 'EnvironmentName', 'dev', isGlobal: true
    ComponentParam 'EnvironmentType', 'development', allowedValues: ['development','production'], isGlobal: true
  end


end
